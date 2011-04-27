module Exceptron
  module LocalHelpers
    def application_trace
      clean_backtrace(exception, :silent)
    end

    def framework_trace
      clean_backtrace(exception, :noise)
    end

    def full_trace
      clean_backtrace(exception, :all)
    end

    def debug_hash(hash)
      hash.map { |k, v| "#{k}: #{v.inspect}" }.sort.join("\n")
    end

  protected

    def clean_backtrace(exception, *args)
      Rails.respond_to?(:backtrace_cleaner) && Rails.backtrace_cleaner ?
        Rails.backtrace_cleaner.clean(exception.backtrace, *args) :
        exception.backtrace
    end
  end
end
