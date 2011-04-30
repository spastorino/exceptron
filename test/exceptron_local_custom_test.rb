require 'test_helper'

class ExceptronLocalCustomTest < ActionDispatch::IntegrationTest
  def setup
    # Hack to test inherited hook
    klass = Class.new(Exceptron::LocalExceptionsController) do
      def self.name
        'LocalExceptionsCustomController'
      end

      prepend_view_path File.expand_path('../views', __FILE__)

      def internal_server_error
        respond_to do |format|
          format.html { super }
          format.json { render :json => exception_presenter.to_json }
        end
      end

      def not_found
        respond_to do |format|
          format.html { render :action => Exceptron.rescue_templates[exception_presenter.original_exception.class.name] }
          format.xml { render :xml => exception_presenter.to_xml }
        end
      end
    end

    Object.const_set klass.name, klass
  end

  def teardown
    Object.send :remove_const, 'LocalExceptionsCustomController'
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
        assert_select 'h1', "[CUSTOM] Unknown action"
        assert_select 'p', "[CUSTOM] AbstractController::ActionNotFound"
      end

      get "/method_not_allowed"
      assert_response 405
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'title', "Exceptron: Exception caught"
      assert_select 'body' do
        assert_select 'h1', "ActionController::MethodNotAllowed"
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
      assert_select 'h1', "[CUSTOM] Unknown action"
      assert_select 'p', "[CUSTOM] AbstractController::ActionNotFound"
    end

    get "/method_not_allowed"
    assert_response 405
    assert_equal 'text/html', response.content_type.to_s
    assert_select 'title', "Exceptron: Exception caught"
    assert_select 'body' do
      assert_select 'h1', "ActionController::MethodNotAllowed"
    end
  end

  test "localize public rescue message" do
    old_locale, I18n.locale = I18n.locale, :da

    begin
      @app = DevelopmentApp

      get "/"
      assert_response 500
      assert_equal 'text/html', response.content_type.to_s
      assert_match /500 localized error fixture/, body

      get "/not_found"
      assert_response 404
      assert_equal 'text/html', response.content_type.to_s
      assert_select 'title', "Exceptron: Exception caught"
      assert_select 'body' do
        assert_select 'h1', "[CUSTOM] Unknown action"
        assert_select 'p', "[CUSTOM] AbstractController::ActionNotFound"
      end
    ensure
      I18n.locale = old_locale
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
      assert_select 'h1', "[CUSTOM] Unknown action"
      assert_select 'p', "[CUSTOM] AbstractController::ActionNotFound"
    end
  end

  test "rescue other formats in public from a remote ip" do
    @app = ProductionApp
    ['127.0.0.1', '127.0.0.127', '::1', '0:0:0:0:0:0:0:1', '0:0:0:0:0:0:0:1%0'].each do |ip_address|
      self.remote_addr = ip_address

      get "/", {}, 'HTTP_ACCEPT' => 'application/json'
      assert_response 500
      assert_equal 'application/json', response.content_type.to_s
      assert_match %r{"message":"Internal Server Error"}, response.body
      assert_match %r{"status":500}, response.body

      get "/not_found", {}, 'HTTP_ACCEPT' => 'application/xml'
      assert_response 404
      assert_equal 'application/xml', response.content_type.to_s
      assert_match %r{<message>Not Found</message>}, response.body
      assert_match %r{<status type="integer">404</status>}, response.body
    end
  end
end
