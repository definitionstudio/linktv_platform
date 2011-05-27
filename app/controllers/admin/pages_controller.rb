class Admin::PagesController < Admin::AdminController

  active_scaffold :pages do |config|
    config.label = 'Pages'
    config.actions.add :delete
    config.list.columns =
      [:name, :path, :active, :deleted]
    config.show.columns =
      [:name, :path, :content, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :path, :content, :active]
    config.update.columns.add :deleted
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
    # TODO
    #config.columns[:content].form_ui = :text_editor
  end
  
  include Admin::DeletedInactiveFilters

end
