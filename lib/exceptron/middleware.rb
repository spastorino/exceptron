module Exceptron
  class Middleware
    def initialize(app, consider_all_requests_local)
      @app = app
      @dispatcher = Dispatcher.new(consider_all_requests_local)
    end

    def call(env)
      begin
        status, headers, body = @app.call(env)
        exception = nil

        # Only this middleware cares about RoutingError. So, let's just raise
        # it here.
        if headers['X-Cascade'] == 'pass'
          raise ActionController::RoutingError, "No route matches #{env['PATH_INFO'].inspect}"
        end
      rescue Exception => exception
        raise exception unless Exceptron.enabled?
        env["exceptron.exception"] = exception
      end

      exception ? @dispatcher.dispatch(env, exception) : [status, headers, body]
    end
  end
end
