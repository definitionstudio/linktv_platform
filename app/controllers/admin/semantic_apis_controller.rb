class Admin::SemanticApisController < Admin::AdminController

  active_scaffold :semantic_apis do |config|
    config.label = "Semantic API's"
    config.actions.add :delete
    config.list.columns =
      [:name, :url, :lifetime, :active]
    config.show.columns =
      [:name, :url, :query_params, :quota_config, :lifetime, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :url, :query_params, :quota_config, :lifetime, :active]
    config.update.columns.add :deleted
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end

  include Admin::DeletedInactiveFilters

end
