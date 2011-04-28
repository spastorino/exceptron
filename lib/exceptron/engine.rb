module Exceptron
  class Engine < Rails::Engine
    config.exceptron = Exceptron

    initializer "exceptron.swap_middlewares" do |app|
      app.middleware.swap "ActionDispatch::ShowExceptions",
        "Exceptron::Middleware", app.config.consider_all_requests_local
    end

    config.after_initialize do
      config.exceptron.enable!
      config.exceptron.controller ||= Exceptron::ExceptionsController
      config.exceptron.local_controller ||= Exceptron::LocalExceptionsController
    end
  end
end
