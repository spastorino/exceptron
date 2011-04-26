module Exceptron
  class ExceptionsController < ActionController::Base
    append_view_path File.expand_path("../views", __FILE__)
    include Exceptron::Helpers
    respond_to :html, :xml, :json

    def internal_server_error
      respond_with exception
    end
    alias not_found internal_server_error
    alias unprocessable_entity internal_server_error

    def self.inherited(subclass)
      super
      Exceptron.controller = subclass
    end
  end
end
