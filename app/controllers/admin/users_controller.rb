class Admin::UsersController < Admin::AdminController

  active_scaffold :users do |config|
    config.list.columns =
      [:login, :display_name, :email, :roles, :login_count, :request_count, :current_login_at,
        :last_login_at, :created_at, :active]
    config.show.columns =
      [:login, :display_name, :location, :email, :roles, :login_count, :request_count,
        :current_login_ip, :current_login_at, :last_login_ip, :last_login_at, :last_request_at,
        :created_at, :updated_at, :active, :deleted]
    config.create.columns = config.update.columns =
      [:login, :display_name, :location, :email, :roles, :active]
    config.columns[:roles].form_ui = :select
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  protected

  before_filter :has_authlogic
  def has_authlogic
    if defined? Authlogic
      # add password fields to scaffold
      active_scaffold_config.columns.add :password
      active_scaffold_config.columns.add :password_confirmation
      active_scaffold_config.create.columns.add :password
      active_scaffold_config.create.columns.add :password_confirmation
      active_scaffold_config.update.columns.add :password
      active_scaffold_config.update.columns.add :password_confirmation
      active_scaffold_config.columns[:password].form_ui = :password
      active_scaffold_config.columns[:password_confirmation].form_ui = :password
    end
  end

  before_filter :authorize_action
  def authorize_action
    return if authorized? :super_admin
    case params[:action]
    when 'new', 'create', 'update'
      authorize :user_admin
    end
  end

  def create_authorized?
    return true if authorized? :super_admin
    authorized? :user_admin
  end

  def update_authorized?
    return true if authorized? :super_admin
    authorized? :user_admin
  end

  def before_create_save record
    # Must tell the user model which roles are allowed to be set based on the logged-in users's roles
    # super_admin can do anything, other roles can only enable users with their own roles
    if authorized? :super_admin
      record.allowable_roles = Role.active.all
      return
    end
    record.allowable_roles = current_user.roles
  end
  alias_method :before_update_save, :before_create_save

end
