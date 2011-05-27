class Admin::ContentTypesController < Admin::AdminController

  active_scaffold :content_types do |config|
    config.label = 'Content Types'
    config.actions.add :delete
    config.list.columns =
      config.create.columns = config.update.columns =
      [:name, :description, :semantic_apis, :item_type, :display_order, :active]
    config.update.columns.add :deleted
    config.show.columns =
      [:display_order, :name, :description, :semantic_apis, :item_type, :active, :deleted, :created_at, :updated_at]
    config.columns[:semantic_apis].form_ui = :select
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

end
