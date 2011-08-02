# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Move to abstract_unit.rb
module Exceptron
  class Dispatcher
    protected
    undef :logger
    # Silence logger
    def logger
      nil
    end
  end
end

Boomer = lambda do |env|
  req = ActionDispatch::Request.new(env)
  case req.path
  when "/not_found"
    raise AbstractController::ActionNotFound
  when "/method_not_allowed"
    raise ActionController::MethodNotAllowed
  when "/not_implemented"
    raise ActionController::NotImplemented
  when "/unprocessable_entity"
    raise ActionController::InvalidAuthenticityToken
  when "/not_found_original_exception"
    raise ActionView::Template::Error.new(ActionView::Template::Text.new('template'), {}, AbstractController::ActionNotFound.new)
  else
    raise "puke!"
  end
end

ProductionApp = Exceptron::Middleware.new(Boomer, false)
DevelopmentApp = Exceptron::Middleware.new(Boomer, true)

