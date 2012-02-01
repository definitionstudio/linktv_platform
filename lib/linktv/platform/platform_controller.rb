module Linktv::Platform::PlatformController

  class << self

    def included app
      app.module_eval do
        helper :platform

        # Expose helper methods defined elsewhere
        helper_method :render_to_string
        
        helper_method :site_name
        helper_method :auth_present?
        helper_method :authorized?
        helper_method :current_user

        after_filter :check_flash
      end
    end
    
  end

  public

  # Note: cookie should only be set on non-cacheable accesses.
  # Webkit will otherwise cache them with the response.
  def set_user_session value
    if value
      cookies[:user_session_valid] = 1
    else
      cookies[:user_session_valid] = 0
    end
  end

  def user_session_valid
    false
  end

  def check_flash
    # If there are any flash messages, disable caching, if enabled
    # WebKit caches the response header along with the page content, so page
    # refreshes would refresh flash messages.
    return if flash.empty?
    expires_now
  end

  def site_name
    APP_CONFIG[:site][:name] rescue "Link TV Platform"
  end

  # Note: ApplicationController should override to provide access control
  def auth_present?
    false
  end
  # Note: ApplicationController should override to provide access control
  def authorized? role = nil
    true
  end

  # Note: ApplicationController should override to provide access control
  def current_user
    nil
  end

  # Note: ApplicationController should override to provide access control
  def authorize role = nil
    true
  end

  # override exception logging for benign exceptions (ExceptionLoggable)
  def log_exception(exception)
    return if @@benign_exceptions.include? exception.class
    super(exception)
  end

  # define benign exceptions
  @@benign_exceptions = [Exceptions::HTTPBadRequest, Exceptions::HTTPUnauthorized,
    Exceptions::HTTPNotFound, ActionController::InvalidAuthenticityToken,
    Exceptions::Unauthorized, ActionController::MethodNotAllowed]

end
