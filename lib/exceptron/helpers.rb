module Exceptron
  module Helpers
    extend ActiveSupport::Concern

    included do
      before_filter :set_status_code
      helper_method :exception
    end

    protected

    def set_status_code
      self.status = exception.status_code
    end

    def exception
      @exception ||= env["exceptron.exception"]
    end
  end
end
