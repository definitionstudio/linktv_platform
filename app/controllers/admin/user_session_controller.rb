class Admin::UserSessionController < Admin::AdminController

  skip_before_filter :authorize_admin, :only => [:new, :create, :edit, :update]

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      # Block handler required due to authlogic openid redirect process
      if result
        set_user_session true
        flash[:notice] = "Sign-in successful."
        redirect_back_or_default admin_home_url
      else
        render :action => :new
      end
    end
  end

  def update
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      # Block handler required due to authlogic openid redirect process
      if result
        respond_to do |format|
          format.json {
            render :json => {:status => :success}
          }
        end
      else
        # Restore the original user session object, so it will still look like an update (i.e. timeout re-entry)
        # rather than a new login. Copy the faked ActiveRecord error messages over.
        @user_session = current_user_session
        @user = @user_session.attempted_record
        @message = "Login/password combination was not recognized."
        js = render_to_string :partial => 'admin/user_session/renew.js.erb'
        respond_to do |format|
          format.json {
            render :json => {
              :status => :session_expired,
              :js => js
            },
            :status => :unauthorized
          }
        end
      end
    end
  end

  def do_create
  end

  def destroy
    current_user_session.destroy
    set_user_session true
    flash[:notice] = "Sign-out successful."
    redirect_back_or_default admin_login_url
  end
end
