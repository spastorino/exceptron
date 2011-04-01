require 'test_helper'

class ExceptronPublicTest < ActionDispatch::IntegrationTest
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
    assert_select 'title', "The page you were looking for doesn't exist (404)"
    assert_select 'body' do
      assert_select 'h1', "The page you were looking for doesn't exist."
      assert_select 'p', "You may have mistyped the address or the page may have moved."
    end

    get "/method_not_allowed"
    assert_response 405
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "We're sorry, but something went wrong (405)"
    assert_select 'body' do
      assert_select 'h1', "We're sorry, but something went wrong."
      assert_select 'p', "We've been notified about this issue and we'll take a look at it shortly."
    end
  end

  test "show registered original exception for wrapped exceptions when consider_all_requests_local is false" do
    @app = ProductionApp
    self.remote_addr = '208.77.188.166'

    get "/not_found_original_exception"
    assert_response 404
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "The page you were looking for doesn't exist (404)"
    assert_select 'body' do
      assert_select 'h1', "The page you were looking for doesn't exist."
      assert_select 'p', "You may have mistyped the address or the page may have moved."
    end
  end
end
