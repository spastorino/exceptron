class Exception
  delegate :status_code, :status_message, :to => :"self.class"

  def self.status_code
    500
  end

  def self.status_message
    status = Rack::Utils::HTTP_STATUS_CODES[status_code]
    status.to_s if status
  end

  def to_xml(options={})
    _serialize(:xml, options)
  end

  def to_json(options={})
    _serialize(:json, options)
  end

  def registered_exception
    if registered_original_exception?
      original_exception
    else
      self
    end
  end

  def registered_original_exception?
    respond_to?(:original_exception) && Exceptron.rescue_templates[original_exception.class.name]
  end

  protected

  def _serialize(serializer, options) #:nodoc:
    hash    = { :status => status_code, :message => status_message }
    options = { :root => "error" }.merge!(options)
    hash.send(:"to_#{serializer}", options)
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
