# Extend delayed_job to use exception_loggable

begin
  require 'delayed_job'
  require 'exception_loggable'
rescue LoadError
  # Fail silently if libraries are not available
else
  module Delayed
    module Backend
      module Base
        include ExceptionLoggable

        def invoke_job_with_linktv_platform
          begin
            invoke_job_without_linktv_platform
          rescue => exception
            message = exception.message.inspect
            e = LoggedException.create! \
              :exception_class => exception.class.name,
              :controller_name => 'delayed_job',
              :action_name     => nil,
              :message         => message,
              :backtrace       => exception.backtrace,
              :request         => self.name

            LoggedException.deliver_exception(e)

            raise
          end
        end
        alias_method_chain :invoke_job, :linktv_platform
      end
    end
  end
end
