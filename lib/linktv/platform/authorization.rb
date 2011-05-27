# Optional authorization module (requires Authlogic)
# Include in ApplicationController

# Not necessarily restricted for use by ActionController instances.
# Calling class should rescue or rescue_from Exceptions::Unauthorized to respond appropriately.

module Linktv::Platform::Authorization

  # Always check the user session so cookie state is accurate
  def user_session_valid
    # Don't cache this value, it might change during signin/out requests
    current_user && current_user.live?
  end

  def auth_present?
    true
  end

  def authorized? role = nil
    return true if @authorization_override || nil
    return false unless defined? Authlogic
    return false unless user_session_valid

    roles = current_user.roles.collect{|r| r.name}
    return true if role.nil? || roles.include?(role.to_s)
  end

  # Authorize by role, raising an exception if unauthorized
  def authorize role = nil
    logger.debug("****** Authorization.authorize #{role} ********")
    return true if authorized? role
    # Not authorized
    raise Exceptions::Unauthorized
  end

  private

  def current_user_session
    begin
      @current_user_session ||= UserSession.find
    rescue NoMethodError
      nil
    end
  end

  def current_user
    @current_user ||= current_user_session ? current_user_session.user : nil
  end

  def store_location uri = nil
    session[:return_to] = uri || request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

end
