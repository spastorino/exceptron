module Exceptron
  class Middleware
    LOCALHOST = ['127.0.0.1', '::1'].freeze

    DEFAULT_ACTION = "internal_server_error"

    FAILSAFE_RESPONSE = [500, {'Content-Type' => 'text/html'},
      ["<html><body><h1>500 Internal Server Error</h1>" <<
       "If you are the administrator of this website, then please read this web " <<
       "application's log file and/or the web server's log file to find out what " <<
       "went wrong.</body></html>"]]

    def initialize(app, consider_all_requests_local)
      @app, @consider_all_requests_local = app, consider_all_requests_local
    end

    def call(env)
      status, headers, body = @app.call(env)

      if headers['X-Cascade'] == 'pass'
        raise ActionController::RoutingError, "No route matches #{env['PATH_INFO'].inspect}"
      end

      [status, headers, body]
    rescue Exception => exception
      env["exceptron.exception"] = exception
      render_exception(env, exception)
    end

  protected

    def render_exception(env, exception)
      # log_error(exception)

      # TODO Freeze sessions and cookies

      controller = exceptions_controller(env)
      action = exception_action(exception)


      if controller.action_methods.include?(action)
        controller.action(action).call(env)
      elsif controller.action_methods.include?(DEFAULT_ACTION)
        controller.action(DEFAULT_ACTION).call(env)
      else
        FAILSAFE_RESPONSE
      end
    rescue Exception => failsafe_error
      $stderr.puts "Error during failsafe response: #{failsafe_error}"
      FAILSAFE_RESPONSE
    end

    def exceptions_controller(env)
      request = ActionDispatch::Request.new(env)

      if @consider_all_requests_local || local_request?(request)
        Exceptron::LocalExceptionsController
      else
        @_exceptions_controller ||= Exceptron.controller.constantize
      end
    end

    def exception_action(exception)
      Rack::Utils::HTTP_STATUS_CODES[exception.status_code].to_s
    end

    def local_request?(request)
      LOCALHOST.any? do |local_ip|
        request.remote_addr == local_ip && request.remote_ip == local_ip
      end
    end

    def log_error(exception)
      return unless logger

      ActiveSupport::Deprecation.silence do
        if ActionView::Template::Error === exception
          logger.fatal(exception.to_s)
        else
          logger.fatal(
            "\n#{exception.class} (#{exception.message}):\n  " +
            clean_backtrace(exception).join("\n  ") + "\n\n"
          )
        end
      end
    end

    def logger
      defined?(Rails.logger) ? Rails.logger : Logger.new($stderr)
    end
  end
end