module Exceptron
  class ExceptionsController < ActionController::Base
    append_view_path File.expand_path("../views", __FILE__)
    include Exceptron::Helpers

    def internal_server_error; end
    def not_found; end
    def unprocessable_entity; end

    def self.inherited(subclass)
      super
      Exceptron.controller = subclass
    end
  end
end
