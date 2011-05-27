class Admin::LinksController < Admin::AdminController

  active_scaffold :links do |config|
    config.label = 'Links'
    config.actions.add :delete
    config.list.columns =
      [:group, :name, :page, :url, :target, :display_order, :active, :deleted]
    config.show.columns =
      [:group, :name, :page, :url, :target, :display_order, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:group, :name, :page, :url, :target, :display_order, :active]
    config.update.columns.add :deleted
    config.columns[:page].form_ui = :select
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

end
