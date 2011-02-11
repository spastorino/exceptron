require 'test_helper'

# Move to abstract_unit.rb
module Exceptron
  class Middleware
    protected
    undef :logger
    # Silence logger
    def logger
      nil
    end
  end
end

class ExceptionTestController < ActionController::Base
  self.view_paths = File.expand_path('../views', __FILE__)

  respond_to :html, :xml, :json
  include Exceptron::Helpers

  def not_found
    respond_with exception
  end

  def internal_server_error
    respond_with exception
  end
end

class ExceptronTest < ActionDispatch::IntegrationTest
  # FAILSAFE_RESPONSE = "<html><head><title>500 Internal Server Error</title></head>" <<
  #                     "<body><h1>500 Internal Server Error</h1>If you are the administrator of " <<
  #                     "this website, then please read this web application's log file and/or the " <<
  #                     "web server's log file to find out what went wrong.</body></html>"

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

  Exceptron.controller = "ExceptionTestController"
  ProductionApp = Exceptron::Middleware.new(Boomer, false)
  DevelopmentApp = Exceptron::Middleware.new(Boomer, true)

  test "rescue in public from a remote ip" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/"
    assert_response 500
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (Internal Server Error)"
    assert_select 'body' do
      assert_select 'h1', "We're sorry, but something went wrong."
      assert_select 'p', "We've been notified about this issue and we'll take a look at it shortly."
    end

    get "/not_found"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (Not Found)"
    assert_select 'body' do
      assert_select 'h1', "The page you were looking for doesn't exist."
      assert_select 'p', "You may have mistyped the address or the page may have moved."
    end

    get "/method_not_allowed"
    assert_response 405
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (Method Not Allowed)"
    assert_select 'body' do
      assert_select 'h1', "We're sorry, but something went wrong."
      assert_select 'p', "We've been notified about this issue and we'll take a look at it shortly."
    end
  end

  test "rescue locally from a local request" do
    @app = ProductionApp
    ['127.0.0.1', '127.0.0.127', '::1', '0:0:0:0:0:0:0:1', '0:0:0:0:0:0:0:1%0'].each do |ip_address|
      self.remote_addr = ip_address

      get "/"
      assert_response 500
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'title', "Exceptron: Exception caught"
      assert_select 'body' do
        assert_select 'h1', "RuntimeError"
      end
      assert_match(/puke/, body)

      get "/not_found"
      assert_response 404
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'body' do
        assert_select 'h1', "Unknown action"
        assert_select 'p', "AbstractController::ActionNotFound"
      end

      get "/method_not_allowed"
      assert_response 405
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'body' do
        assert_select 'h1', "ActionController::MethodNotAllowed"
      end
    end
  end

  test "localize public rescue message" do
    # Change locale
    old_locale, I18n.locale = I18n.locale, :da

    begin
      @app = ProductionApp
      self.remote_addr = '208.77.188.166'

      get "/"
      assert_response 500
      assert_equal 'text/html', response.content_type.to_s
      assert_match /500 localized error fixture/, body

      get "/not_found"
      assert_response 404
      assert_select 'title', "We're sorry, but something went wrong (Not Found)"
      assert_select 'body' do
        assert_select 'h1', "The page you were looking for doesn't exist."
        assert_select 'p', "You may have mistyped the address or the page may have moved."
      end
    ensure
      I18n.locale = old_locale
    end
  end

  test "always rescue locally in development mode" do
    @app = DevelopmentApp
    self.remote_addr = '208.77.188.166'

    get "/"
    assert_response 500
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "Exceptron: Exception caught"
    assert_select 'body' do
      assert_select 'h1', "RuntimeError"
    end
    assert_match(/puke/, body)

    get "/not_found"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'body' do
      assert_select 'h1', "Unknown action"
      assert_select 'p', "AbstractController::ActionNotFound"
    end

    get "/method_not_allowed"
    assert_response 405
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'body' do
      assert_select 'h1', "ActionController::MethodNotAllowed"
    end
  end

  test "does not show filtered parameters" do
    @app = DevelopmentApp

    get "/", {"foo"=>"bar"}, { 'action_dispatch.parameter_filter' => [:foo] }
    assert_response 500
    assert_equal 'text/html', response.content_type.to_s
    assert_match("&quot;foo&quot;=&gt;&quot;[FILTERED]&quot;", body)
  end

  test "show registered original exception for wrapped exceptions when consider_all_requests_local is false" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/not_found_original_exception"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (Not Found)"
    assert_select 'body' do
      assert_select 'h1', "The page you were looking for doesn't exist."
      assert_select 'p', "You may have mistyped the address or the page may have moved."
    end
  end

  test "show registered original exception for wrapped exceptions when consider_all_requests_local is true" do
    @app = DevelopmentApp

    get "/not_found_original_exception"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'body' do
      assert_select 'h1', "Unknown action"
      assert_select 'p', "AbstractController::ActionNotFound"
    end
  end
end
