class SuperAdmin::EntityIdentifiersController < SuperAdmin::SuperAdminController

  active_scaffold :entity_identifiers do |config|
    config.label = 'Entity Identifiers'
    config.columns[:topic].form_ui = :select
    config.columns[:entity_db].form_ui = :select
    config.list.columns = config.create.columns = config.update.columns =
      [:identifier, :topic, :entity_db]
    config.show.columns =
      [:identifier, :topic, :entity_db, :created_at, :updated_at]
  end
  
  include Admin::DeletedInactiveFilters

end
