require 'test_helper'

class ExceptronPublicCustomTest < ActionDispatch::IntegrationTest
  def setup
    # Hack to test inherited hook
    klass = Class.new(Exceptron::ExceptionsController) do
      def self.name
        'ExceptionsCustomController'
      end

      prepend_view_path File.expand_path('../views', __FILE__)
    end

    Object.const_set klass.name, klass
  end

  def teardown
    Object.send :remove_const, 'ExceptionsCustomController'
    Exceptron.controller = Exceptron::ExceptionsController
  end

  test "rescue in public from a remote ip" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/"
    assert_response 500
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (500)"
    assert_select 'body' do
      assert_select 'h1', "We're sorry, but something went wrong."
      assert_select 'p', "We've been notified about this issue and we'll take a look at it shortly."
    end

    get "/not_found"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "[CUSTOM] The page you were looking for doesn't exist (404)"
    assert_select 'body' do
      assert_select 'h1', "[CUSTOM] The page you were looking for doesn't exist."
      assert_select 'p', "[CUSTOM] You may have mistyped the address or the page may have moved."
    end

    get "/method_not_allowed"
    assert_response 405
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (405)"
    assert_select 'body' do
      assert_select 'h1', "We're sorry, but something went wrong."
      assert_select 'p', "We've been notified about this issue and we'll take a look at it shortly."
    end

    get "/not_implemented"
    assert_response 501
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "[CUSTOM] 501 Not Implemented"
    assert_select 'body' do
      assert_select 'h1', "[CUSTOM] 501 Not Implemented"
      assert_select 'p', "[CUSTOM] 501 Not Implemented"
    end
  end

  test "localize public rescue message" do
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
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'title', "[CUSTOM] The page you were looking for doesn't exist (404)"
      assert_select 'body' do
        assert_select 'h1', "[CUSTOM] The page you were looking for doesn't exist."
        assert_select 'p', "[CUSTOM] You may have mistyped the address or the page may have moved."
      end
    ensure
      I18n.locale = old_locale
    end
  end

  test "does not show filtered parameters" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/not_implemented", {"foo"=>"bar"}, { 'action_dispatch.parameter_filter' => [:foo] }
    assert_response 501
    assert_equal 'text/html', response.content_type.to_s
    assert_match("&quot;foo&quot;=&gt;&quot;[FILTERED]&quot;", body)
  end

  test "show registered original exception for wrapped exceptions when consider_all_requests_local is false" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/not_found_original_exception"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "[CUSTOM] The page you were looking for doesn't exist (404)"
    assert_select 'body' do
      assert_select 'h1', "[CUSTOM] The page you were looking for doesn't exist."
      assert_select 'p', "[CUSTOM] You may have mistyped the address or the page may have moved."
    end
  end

  test "rescue other formats in public from a remote ip" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/", {}, 'HTTP_ACCEPT' => 'application/json'
    assert_response 500
    assert_equal 'application/json', response.content_type.to_s
    assert_match %r{"message":"CUSTOM Internal Server Error"}, response.body
    assert_match %r{"status":500}, response.body

    get "/not_found", {}, 'HTTP_ACCEPT' => 'application/xml'
    assert_response 404
    assert_equal 'application/xml', response.content_type.to_s
    assert_match %r{<message>CUSTOM Not Found</message>}, response.body
    assert_match %r{<status type="integer">404</status>}, response.body
  end
end
