module Exceptron
  module Helpers
    extend ActiveSupport::Concern

    included do
      before_filter :set_status_code
      helper_method :exception_presenter, :exception
    end

    protected

    def set_status_code
      self.status = exception_presenter.status_code
    end

    def exception_presenter
      @presenter ||= env["exceptron.presenter"]
    end

    def exception
      @exception ||= exception_presenter.wrapped_exception
    end
  end
end
