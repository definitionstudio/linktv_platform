class SuperAdmin::VideoFilesController < SuperAdmin::SuperAdminController

  active_scaffold :video_files do |config|
    config.list.columns =
      [:video, :url, :cdn_path, :file_size, :mime_type, :bitrate, :status, :active, :deleted]
    config.show.columns =
      [:video, :url, :cdn_path, :file_size, :mime_type, :bitrate, :status,
      :created_at, :updated_at, :active, :deleted]
    config.create.columns = config.update.columns =
      [:video, :url, :cdn_path, :file_size, :mime_type, :bitrate, :active, :deleted]
    config.columns[:video].form_ui = :select
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

end
