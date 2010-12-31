module Exceptron
  class Middleware
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
      exception = original_exception(exception)

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
      @consider_all_requests_local || request.local? ?
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

    def log_error(exception)
      return unless logger

      ActiveSupport::Deprecation.silence do
        message = "\n#{exception.class} (#{exception.message}):\n"
        message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
        # message << "  " << application_trace.join("\n  ")
        message << exception.backtrace.join("\n  ")
        logger.fatal("#{message}\n\n")
      end
    end

    def logger
      defined?(Rails.logger) ? Rails.logger : Logger.new($stderr)
    end

    def original_exception(exception)
      if registered_original_exception?(exception)
        exception.original_exception
      else
        exception
      end
    end

    def registered_original_exception?(exception)
      exception.respond_to?(:original_exception) && Exceptron.rescue_templates[exception.original_exception.class.name]
    end
  end
end
