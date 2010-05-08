module Exceptron
  class Engine < Rails::Engine
    config.exceptron = true

    initializer "exceptron.swap_middlewares" do |app|
      app.middlewares.insert_before "ActionDispatch::ShowExceptions", "Exceptron::Middleware"
      app.middlewares.delete "ActionDispatch::ShowExceptions"
    end
  end
end