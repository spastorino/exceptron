module Exceptron
  class LocalExceptionsController < ActionController::Base
    append_view_path File.expand_path("../views", __FILE__)
    include Exceptron::Helpers

    helper Exceptron::LocalHelpers
    layout "rescues"

    def internal_server_error
      render :action => Exceptron.rescue_templates[exception.class.name]
    end

  protected

    def _prefixex
      %w(rescues)
    end
  end
end