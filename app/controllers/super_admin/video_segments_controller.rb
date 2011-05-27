class SuperAdmin::VideoSegmentsController < SuperAdmin::SuperAdminController

  active_scaffold :video_segments do |config|
    config.label = "Video Segments"
    config.columns[:video].form_ui = :select
    config.list.columns =
    config.create.columns =
    config.show.columns =
    config.update.columns =
      [:name, :video, :start_time, :transcript_text, :active, :deleted]
    config.show.columns =
      [:name, :video, :start_time, :transcript_text, :active, :deleted, :created_at, :updated_at]
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end

  include Admin::DeletedInactiveFilters

end
