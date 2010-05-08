module Exceptron
  class Engine < Rails::Engine
    config.exceptron = true

    initializer "exceptron.swap_middlewares" do |app|
      app.middleware.insert_before "ActionDispatch::ShowExceptions", "Exceptron::Middleware"
      app.middleware.delete "ActionDispatch::ShowExceptions"
    end
  end
end