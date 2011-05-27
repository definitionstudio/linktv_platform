class Admin::AdminController < ApplicationController
  layout "admin"

  before_filter :authorize_admin
  def authorize_admin
    authorize :admin
  end

  before_filter :set_title
  def set_title
    @template.content_for :title, "Admin - " + self.controller_name.titleize
  end

  # override this method for custom admin menu items
  before_filter :set_custom_menu_vars
  def set_custom_menu_vars
    @custom_menu_title = 'Custom';
    @custom_menu_items = [] # array of objects with 'name' and 'path' properties
  end

  before_filter :disable_caching
  def disable_caching
    # No caching in admin
    expires_now
  end


  # ActiveScaffold

  ActiveScaffold.set_defaults do |config|
    # Disable deletion of records. We use a 'deleted' boolean column instead
    config.actions.exclude :delete
    config.list.per_page = 25
  end

  # Disable nested :new and :edit globally, will default to :show
  ActiveScaffold::DataStructures::Column.actions_for_association_links = [:show]

  # deleted item display
  before_filter :show_deleted_column
  def show_deleted_column
    return unless active_scaffold_config.present?
    if (params[:show_deleted].to_i != 0 rescue nil)
      active_scaffold_config.list.columns.add :deleted
    else
      active_scaffold_config.list.columns.exclude :deleted
    end
  end


  # Exception handling

  rescue_from Exceptions::Unauthorized do |exception|
    if request.xhr? && current_user_session && current_user_session.stale? &&
        current_user.roles.map{|r| r.name.to_sym}.include?(:admin) &&
      # Give the user a chance to log in again
      @user_session = current_user_session
      @user = @user_session.attempted_record
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
      return
    end

    # Not authorized
    store_location
    redirect_to new_admin_user_session_url
  end

  def log_exception exception
    logger.error "#{self.class.name} begin #{exception.inspect}"
    exception.backtrace.each do |err|
      logger.error err
    end
    logger.error "#{self.class.name} end #{exception.inspect}"
    # exception_logger plugin (uses same method name)
    begin
      require 'logged_exception'
      super
    rescue LoadError
    end
  end
  protected :log_exception

  rescue_from do |exception|
    log_exception exception
    if request.xhr?
      render :status => :internal_server_error, :json => {
        :status => 'exception',
        :exception => exception.inspect,
        :backtrace => exception.backtrace,
        :msg => exception.to_s
      }
    else
      render 'admin/exception', :layout => !request.xhr?, :locals => {:exception => exception}
    end
  end
  
  # Send an AJAX response that will be redirected by the client
  # This is not a standard HTTP redirect
  def xhr_redirect url, args = {}
    # Don't clear flash since we're redirecting
    self.class.skip_after_filter :clear_flashes
    render :json => {
      :status => args[:status] || :success,
      :redirect_url => url
    }, :status => args[:status] || :ok
  end
  protected :xhr_redirect

end


# Include this module after the active_scaffold definition in your controller
# to enable non-destructive deletes

module Admin::DeletedInactiveFilters

  def conditions_for_collection
    conditions = nil
    # Delete both the hide and show "index" actions if they are present
    # active_scaffold keys action links by action, so we can't add/delete them individually.
    # Remember that in production these are cached).
    # https://github.com/activescaffold/active_scaffold/wiki/Per-Request-Configuration
    active_scaffold_config.action_links.delete :index

    if active_scaffold_config.columns.include?(:deleted)
      if !(params[:show_deleted].to_i != 0 rescue nil)
        conditions = merge_conditions conditions, "#{active_scaffold_config.model.table_name}.deleted = 0"

        active_scaffold_config.action_links.add :index, :label => 'Show Deleted', :type => :collection,
          :page => true,
          :parameters => {:show_deleted => 1}
      else
        active_scaffold_config.action_links.add :index, :label => 'Hide Deleted', :type => :collection,
          :page => true,
          :parameters => {:show_deleted => 0}
      end
    end

    conditions
  end

  # override destroy (set 'deleted' bit)
  def do_destroy
    @record = find_if_allowed(params[:id], :update)
    begin
      @record.update_attributes!(:deleted => 1)
      self.successful = true
    rescue
      self.successful = false
      flash[:error] = 'Internal Error'
    end
  end

end
