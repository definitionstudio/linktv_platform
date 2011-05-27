class Admin::EntityDbsController < Admin::AdminController

  active_scaffold :entity_dbs do |config|
    config.label = 'Entity Databases'
    config.actions.add :delete
    config.list.columns = [:name, :description, :url, :active]
    config.show.columns =
      [:name, :description, :url, :icon_css_class, :identifier_regex, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :description, :url, :icon_css_class, :identifier_regex, :active]
    config.update.columns.add :deleted
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

  def autocomplete
    # TODO caching
    entity_db = EntityDb.find_by_id params[:id]
    data = entity_db.autocomplete params[:q]

    respond_to do |format|
      format.json {
        render :json => data
      }
    end
  end

end
