require 'test_helper'

class ExceptronLocalTest < ActionDispatch::IntegrationTest
  def setup
    Exceptron.local_controller = Exceptron::LocalExceptionsController
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
      assert_select 'title', "Exceptron: Exception caught"
      assert_select 'body' do
        assert_select 'h1', "Unknown action"
        assert_select 'p', "AbstractController::ActionNotFound"
      end

      get "/method_not_allowed"
      assert_response 405
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'title', "Exceptron: Exception caught"
      assert_select 'body' do
        assert_select 'h1', "ActionController::MethodNotAllowed"
      end
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
    assert_select 'title', "Exceptron: Exception caught"
    assert_select 'body' do
      assert_select 'h1', "Unknown action"
      assert_select 'p', "AbstractController::ActionNotFound"
    end

    get "/method_not_allowed"
    assert_response 405
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "Exceptron: Exception caught"
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

  test "show registered original exception for wrapped exceptions when consider_all_requests_local is true" do
    @app = DevelopmentApp

    get "/not_found_original_exception"
    assert_response 404
    assert_select 'title', "Exceptron: Exception caught"
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'body' do
      assert_select 'h1', "Unknown action"
      assert_select 'p', "AbstractController::ActionNotFound"
    end
  end
end
