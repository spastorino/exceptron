require 'exceptron/engine'
require 'exceptron/exceptions'

module Exceptron
  autoload :Middleware,                'exceptron/middleware'
  autoload :VERSION,                   'exceptron/version'
  autoload :LocalExceptionsController, 'exceptron/local_exceptions_controller'

  def self.enable!
    @@enabled = true
  end

  def self.disable!
    @@enabled = false
  end

  def self.enabled?
    @@enabled
  end

  def self.controller=(string)
    class_eval "def controller; #{string}; end", __FILE__, __LINE__
  end

  self.enable!
  self.controller = "ExceptionsController"
end