class Admin::ContentSourcesController < Admin::AdminController

  active_scaffold :content_sources do |config|
    config.label = 'Content Sources'
    config.actions.add :delete
    config.list.columns =
      [:name, :description, :base_url, :weight, :active]
    config.create.columns = config.update.columns =
      [:name, :description, :base_url, :favicon_url, :weight, :active]
    config.update.columns.add :deleted
    config.show.columns =
      [:name, :description, :base_url, :favicon_url, :weight, :active, :deleted, :created_at, :updated_at]
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox

    config.columns[:weight].description =
      "External content from this source will have its score multiplied by this value. " +
      "Set to 0.0 to blacklist a site, less than 1.0 de de-emphasize content from the site, " +
      "greater than 1.0 but less than 2.0 to emphasize."
  end
  
  include Admin::DeletedInactiveFilters

end
