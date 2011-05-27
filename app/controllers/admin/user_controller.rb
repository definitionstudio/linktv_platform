class Admin::UserController < Admin::AdminController

  before_filter :find_user
  def find_user
    @user = current_user
  end

  def show
  end

  def edit
  end

  def update
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete :password
      params[:user].delete :password_confirmation
    end

    if !@user.valid_password?(params[:user][:current_password])
      @user.errors.add :current_password, "is incorrect"
      render :action => 'edit'
      return
    end

    if @user.update_attributes params[:user]
      flash[:notice] = "Your account profile has been updated."
      redirect_to :action => 'show'
    else
      render :action => 'edit'
    end
  end
  
end
