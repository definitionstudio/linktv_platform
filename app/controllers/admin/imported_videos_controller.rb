class Admin::ImportedVideosController < Admin::AdminController

  active_scaffold :imported_videos do |config|
    config.actions = [:list, :search]
    config.list.label = 'Imported Videos'
    config.list.columns = [:name, :source_published_at, :link, :video_source, :status]
  end

  helper :videos, :images

  before_filter :update_as_config
  def update_as_config
    active_scaffold_config.list.label = "New Videos" if params[:status] == "new"
    active_scaffold_config.list.label = "Rejected Videos" if params[:status] == "rejected"
  end

  def edit
    @video = ImportedVideo.find params[:id]
    @video_files = @video.video_files
    render 'admin/videos/edit.haml'
  end

  def update
    if params[:operation] == 'reject'
      return reject
    end

    if params[:operation] == 'accept'
      return accept
    end

    flash[:error] = "Unsupported Operation."

		respond_to do |format|
			format.json do
        xhr_redirect admin_imported_video_path(params[:id]), :status => :not_implemented
			end
		end
  end

  def accept
    imported_video = ImportedVideo.find params[:id]
    video = imported_video.accept :user => current_user, :notes => params[:imported_video][:notes]
    if video
      flash[:notice] = "Video accepted."
      respond_to do |format|
        format.json do
          xhr_redirect edit_admin_video_path(video.id)
        end
      end
    else
      raise "Video-accept operation failed."
    end
  end

  def reject
    imported_video  = ImportedVideo.find params[:id]
    if imported_video.reject :user => current_user, :notes => params[:imported_video][:notes]
      flash[:notice] = "Video rejected."
      respond_to do |format|
        format.json do
          xhr_redirect edit_admin_imported_video_path(params[:id])
        end
      end
    else
      raise "Video-reject operation failed."
    end
  end

end
