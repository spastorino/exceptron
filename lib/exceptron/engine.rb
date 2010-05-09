module Exceptron
  class Engine < Rails::Engine
    config.exceptron = Exceptron

    initializer "exceptron.swap_middlewares" do |app|
      app.middleware.swap "ActionDispatch::ShowExceptions",
        "Exceptron::Middleware", app.config.consider_all_requests_local
    end
  end
end