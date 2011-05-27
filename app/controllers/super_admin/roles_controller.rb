class SuperAdmin::RolesController < SuperAdmin::SuperAdminController

  active_scaffold :roles do |config|
    config.label = 'User Roles'
    config.list.columns =
      [:name, :description, :active, :deleted]
    config.show.columns =
      [:name, :description, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :description, :active, :deleted]
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

end
