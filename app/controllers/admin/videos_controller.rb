class Admin::VideosController < Admin::AdminController

  active_scaffold :videos do |config|
    config.actions = [:list, :show, :search, :nested, :create, :update, :delete]
    config.update.link.page = true  # edit link behaves like a link to /videos/:id/edit
    config.list.columns = [
      :id, :name, :video_source, :duration,
      :video_files, :video_segments,
      :published, :status]
    config.list.sorting = {:id => 'DESC'}
    config.create.columns = [:name]
    config.show.columns = [
      :id, :name, :permalink, :description, :duration,
      :video_source, :video_files, :video_segments,
      :status, :published, :published_at, :recommended, :deleted]

    config.columns[:video_segments].label = 'Segments'

    config.columns[:video_source].form_ui = :select
    config.columns[:regions].form_ui = :select
    config.columns[:recommended].form_ui = :checkbox
    config.columns[:published].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

  helper :images, :videos, :video_segments, 'admin/external_contents'

  def edit
    assign_review_variables

    if params[:id] =~ /\d+/
      conditions = {:id => params[:id]}
    else
      conditions = {:permalink => params[:id]}
    end

    found = false
    begin
      # TODO: the :live_topic nesting doesn't seem to be eager-loading the topics.
      @video = Video.find :first, :conditions => conditions, :include => [
        :imported_video, :thumbnail, :video_files, :regions, :video_segments]
      found = true unless @video.nil?
    rescue ActiveRecord::RecordNotFound
    end

    unless found
      logger.error("Attempt to access invalid video #{params[:id]}")
      flash[:notice] = "Invalid video."
      redirect_to :action => 'index'
      return
    end

    @video_topics = @video.topics_for_admin

    media = {}
    # Fill in existing video files
    video_files = @video.video_files.live

    # put video files in arrays by media_type
    video_files.each do |video_file|
      media[video_file.media_type.to_sym] ||= []
      media[video_file.media_type.to_sym] << video_file
    end

    # Fill in non-existent media instance types and create provision video files
    @video_files = []

    APP_CONFIG[:media_types].each do |media_type_data|

      media_type = media_type_data[:key].to_sym

      media_type_files = media[media_type] || []
      media_type_files.sort{|a, b| a.file_size <=> b.file_size} rescue media_type_files   # sort on filesize (smaller first)

      i = 0

      media_type_data[:media_instance_types].each do |media_instance_type|

        video_file = media_type_files[i] rescue nil
        if video_file.present?
          video_file.media_instance_type = media_instance_type  # assign instance type
          @video_files << video_file
          unless video_file.cdn_path.blank?
            # Make another instance to reflect the CDN version (for the video player)
            cdn_file = video_file.dup
            cdn_file.is_cdn = true
            @video_files << cdn_file
          end
        else
          # Placeholder for non-existent media instance type
          @video_files << @video.video_files.build({
            :active => 1,
            :status => :provisioned,
            :media_type => media_type,
            :media_instance_type => media_instance_type
          })
        end

        i+=1  # increment

      end

    end

    unless @video.resource_attr_by_name 'more_info'
      @video.resource_attrs.build :name => 'more_info', :value => ''
    end
  end

  def update

    @video = Video.find params[:id], :include => :video_segments

    # Add extra data to parameters as necessary for the update
    unless params[:video][:video_segments_attributes].blank?
      
      params[:video][:video_segments_attributes].each do |k, video_segment_attributes|

        # Add missing video_id link in topic_video_segments and external contents
        [:topic_video_segments_attributes, :external_contents_attributes].each do |type|
          (video_segment_attributes[type] || {}).each do |k, attrs|
            attrs[:video_id] = params[:id] unless attrs[:video_id].present?
          end
        end

      end
    end

    params[:video][:duration] = parse_time params[:video][:duration] if params[:video][:duration].present?

    begin
      # Manual transaction, since we are deleting any old content along with the update of the segment
      Video.transaction do

        begin
          logger.debug(params[:video].to_yaml)
          @video.update_attributes! params[:video]
        rescue => exc
          # For debug trapping
          raise exc
        end

        @video.video_files.live.each {|vf| vf.maybe_download_from_source current_user}

        # Delete any non-static external content
        deleted_count = @video.destroy_non_static_external_contents.count

        @video.update_all_external_contents_later

        flash[:notice] = "Video updated."

        if request.accept.match(/^application\/json/)
          respond_to do |format|
            format.json do
              xhr_redirect edit_admin_video_url(@video)
            end
          end
        else
          redirect_to :action => 'edit'
        end
      end
    rescue ActiveRecord::RecordInvalid => exc
      log_exception exc
      if request.accept.match(/^application\/json/)
        raise "The video could not be updated."
      end
      assign_review_variables
      render :action => :edit
    rescue String
      flash[:error] = args[:error] if args[:error].is_a?(String)
    rescue Exception => exc
      log_exception exc
      raise "The video could not be updated."
    end
  end
  
  def undelete
    @video = Video.find params[:id]
    @video.deleted = false
    @video.save
    if request.xhr?
      xhr_redirect edit_admin_video_url(@video)
    else
      redirect_to :action => 'edit'
    end
  end

  protected

  def assign_review_variables
    @content_types = ContentType.live.ordered
    @thumb_config ||= APP_CONFIG[:thumbnails][:default]
  end

  # activescaffold callback
  def before_create_save record
    unless record.video_files.empty?
      record.video_files.each {|f| f.status = :provisioned if f.status.nil?}
    end
  end

end
