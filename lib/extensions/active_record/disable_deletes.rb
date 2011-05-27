class ActiveRecord::Base

  def self.disable_deletes
    # Enforce use of destroy over delete to ensure callbacks are used
    define_method :delete do
      raise Exceptions::UnsupportedOperation
    end

    class << self
      # Enforce use of destroy over delete to ensure callbacks are used
      def delete_all(conditions = nil)
        raise Exceptions::UnsupportedOperation
      end
    end

  end
end
