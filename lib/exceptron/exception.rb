class Exceptron::Exception
  def initialize(exception)
    @wrapped_exception = exception
  end
  attr_reader :wrapped_exception

  def method_missing(method, *args, &block)
    original_exception.send(method, *args, &block)
  end

  def respond_to?(method)
    super || original_exception.respond_to?(method)
  end

  def to_xml(options={})
    _serialize(:xml, options)
  end

  def to_json(options={})
    _serialize(:json, options)
  end

  def original_exception
    if wrapped_exception.respond_to?(:original_exception)
      wrapped_exception.original_exception
    else
      wrapped_exception
    end
  end

  protected

  def _serialize(serializer, options) #:nodoc:
    hash    = { :status => status_code, :message => status_message }
    options = { :root => "error" }.merge!(options)
    hash.send(:"to_#{serializer}", options)
  end
end

class Exception
  def self.status_code
    500
  end

  def status_code
    self.class.status_code
  end

  def self.status_message
    status = Rack::Utils::HTTP_STATUS_CODES[status_code]
    status.to_s if status
  end

  def status_message
    self.class.status_message
  end
end

ActiveSupport.on_load(:action_controller) do
  class ActionController::RoutingError
    def self.status_code; 404; end
  end

  class AbstractController::ActionNotFound
    def self.status_code; 404; end
  end

  class ActionController::MethodNotAllowed
    def self.status_code; 405; end
  end

  class ActionController::NotImplemented
    def self.status_code; 501; end
  end
end

ActiveSupport.on_load(:active_record) do
  class ActiveRecord::RecordNotFound
    def self.status_code; 404; end
  end

  class ActiveRecord::StaleObjectError
    def self.status_code; 409; end
  end

  class ActiveRecord::RecordInvalid
    def self.status_code; 422; end
  end

  class ActiveRecord::RecordNotSaved
    def self.status_code; 422; end
  end
end
