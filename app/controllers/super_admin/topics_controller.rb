class SuperAdmin::TopicsController < SuperAdmin::SuperAdminController
  
	active_scaffold :topics do |config|
    config.list.columns =
      [:name, :description, :entity_identifiers, :live_video_segment_count, :active, :deleted]
    config.show.columns =
      [:name, :description, :entity_identifiers, :guid, :live_video_segment_count, :video_segments, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :description, :entity_identifiers, :active, :deleted]
    config.columns[:description].options = {:html_options => {:rows => 5, :cols => 80}}
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox

    config.columns << :live_video_segment_count
    config.columns[:live_video_segment_count].label = 'Video segments'
  end
  
  include Admin::DeletedInactiveFilters
  
end
