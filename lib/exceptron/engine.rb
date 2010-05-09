module Exceptron
  class Engine < Rails::Engine
    config.exceptron = Exceptron

    initializer "exceptron.swap_middlewares" do |app|
      if Exceptron.enabled?
        app.middleware.insert_before "ActionDispatch::ShowExceptions",
          "Exceptron::Middleware", app.config.consider_all_requests_local
      end

      app.middleware.delete "ActionDispatch::ShowExceptions"
    end
  end
end