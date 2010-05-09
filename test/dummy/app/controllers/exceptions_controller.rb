# You usually wants to inherit from ActionController::Base
# because you don't want authentication settings and other
# before filters to propagate. Bear in mind that you should
# *NOT* do anything special in this controller since any
# error here will return a failsafe response to the client.
class ExceptionsController < ActionController::Base
  respond_to :html, :xml, :json
  include Exceptron::Helpers

  # TODO respond_with won't work for other HTTP verbs.
  # We always want to render the resource.

  def not_found
    respond_with exception
  end

  def internal_server_error
    respond_with exception
  end
end