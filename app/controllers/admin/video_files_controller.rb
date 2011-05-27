class Admin::VideoFilesController < Admin::AdminController

  active_scaffold :video_files do |config|
    config.label = "Video Files"
    config.actions = [:list, :show]
    config.list.columns =
      [:video, :url, :cdn_path, :file_size, :mime_type, :bitrate, :status, :active]
    config.show.columns =
      [:video, :url, :cdn_path, :file_size, :mime_type, :bitrate, :status,
      :created_at, :updated_at, :active, :deleted]
    config.columns[:video].form_ui = :select
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
    config.action_links.add 'download', :label => 'Upload to CDN', :type => :member, :position => false,
      :parameters => {:controller => 'admin/video_files'}, :action => 'download', :method => :post
  end

  def download
    @video_file = VideoFile.find_by_id params[:id]
    @video_file.download_from_source current_user

    # update Active Scaffold row (must set @record first)
    @record = @video_file
    render :action => 'update_row'
  end

end
