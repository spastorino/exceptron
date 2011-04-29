class Exceptron::Exception
  def initialize(exception)
    @wrapped_exception = exception
  end
  attr_reader :wrapped_exception

  class << self
    attr_accessor :statuses
  end
  self.statuses = {}

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

  def status_code
    statuses = self.class.statuses
    registered_exception = original_exception.class.ancestors.find { |klass| statuses.key? klass }
    statuses[registered_exception]
  end

  def status_message
    status = Rack::Utils::HTTP_STATUS_CODES[status_code]
    status.to_s if status
  end

  def actions
    original_exception.class.ancestors.map do |klass|
      status_code = self.class.statuses[klass]
      status = Rack::Utils::HTTP_STATUS_CODES[status_code]
      status.to_s.downcase.gsub(/\s|-/, '_') if status
    end.compact
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
  def self.respond_with(status)
    Exceptron::Exception.statuses[self] = status
  end
  respond_with 500
end

ActiveSupport.on_load(:action_controller) do
  class ActionController::RoutingError
    respond_with 404
  end

  class AbstractController::ActionNotFound
    respond_with 404
  end

  class ActionController::MethodNotAllowed
    respond_with 405
  end

  class ActionController::NotImplemented
    respond_with 501
  end
end

ActiveSupport.on_load(:active_record) do
  class ActiveRecord::RecordNotFound
    respond_with 404
  end

  class ActiveRecord::StaleObjectError
    respond_with 409
  end

  class ActiveRecord::RecordInvalid
    respond_with 422
  end

  class ActiveRecord::RecordNotSaved
    respond_with 422
  end
end
