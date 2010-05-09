module Exceptron
  class Middleware
    LOCALHOST = ['127.0.0.1', '::1'].freeze

    FAILSAFE_RESPONSE = [500, {'Content-Type' => 'text/html'},
      ["<html><head><title>500 Internal Server Error</title></head>" <<
       "<body><h1>500 Internal Server Error</h1>If you are the administrator of " <<
       "this website, then please read this web application's log file and/or the " <<
       "web server's log file to find out what went wrong.</body></html>"]]

    def initialize(app, consider_all_requests_local)
      @app = app
      @consider_all_requests_local = consider_all_requests_local
      @exception_actions = {}
    end

    def call(env)
      status, headers, body = @app.call(env)

      if headers['X-Cascade'] == 'pass'
        raise ActionController::RoutingError, "No route matches #{env['PATH_INFO'].inspect}"
      end

      [status, headers, body]
    rescue Exception => exception
      raise e unless Exceptron.enabled?
      env["exceptron.exception"] = exception
      render_exception(env, exception)
    end

  protected

    def render_exception(env, exception)
      log_error(exception)

      # Freeze session and cookies since any change is not going to be serialized back.
      request = ActionDispatch::Request.new(env)
      request.cookies.freeze
      request.session.freeze

      controller = exception_controller(request)
      action = exception_action(controller, exception.class)

      if action
        controller.action(action).call(env)
      else
        FAILSAFE_RESPONSE
      end
    rescue Exception => failsafe_error
      $stderr.puts "Error during failsafe response: #{failsafe_error}"
      $stderr.puts failsafe_error.backtrace.join("\n")
      FAILSAFE_RESPONSE
    end

    def exception_controller(request)
      @consider_all_requests_local || local_request?(request) ?
        Exceptron::LocalExceptionsController : Exceptron.controller
    end

    def exception_action(controller, exception)
      @exception_actions[exception.name] ||= begin
        action_methods = controller.action_methods
        action = nil

        while exception && exception != Object
          action = exception.status_message.downcase.gsub(/\s|-/, '_')
          break if action_methods.include?(action)
          exception, action = exception.superclass, nil
        end

        action
      end
    end

    def local_request?(request)
      LOCALHOST.any? do |local_ip|
        request.remote_addr == local_ip && request.remote_ip == local_ip
      end
    end

    def log_error(exception)
      return unless logger

      ActiveSupport::Deprecation.silence do
        message = "\n#{exception.class} (#{exception.message}):\n"
        message << exception.annoted_source_code if exception.respond_to?(:annoted_source_code)
        message << exception.backtrace.join("\n  ")
        logger.fatal("#{message}\n\n")
      end
    end

    def logger
      defined?(Rails.logger) ? Rails.logger : Logger.new($stderr)
    end
  end
end