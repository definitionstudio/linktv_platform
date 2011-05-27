class Admin::VideoSegmentsController < Admin::AdminController

  active_scaffold :video_segments do |config|
    config.label = "Video Segments"
    config.actions = [:list, :show]
    config.columns[:video].form_ui = :select
    config.list.columns =
      [:name, :video, :start_time, :transcript_text, :active]
    config.show.columns =
      [:name, :video, :start_time, :transcript_text, :active, :deleted, :created_at, :updated_at]
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end

  helper :images, :video_segments, 'admin/external_contents'

  def edit
    return activescaffold_edit unless params[:review] || nil

    @video_segment = VideoSegment.find_by_id params[:id], :include => [:video, :thumbnail]
    @video = @video_segment.video
    @imported_video = @video.imported_video
    @imported_video_keywords = @video.imported_video_keywords
    @video_topics = @video.topics_for_admin
    @topic_video_segments = @video_segment.topic_video_segments.
      include_topics_and_entity_identifiers.
      ordered
    @content_types = ContentType.live.ordered.find :all
    @semantic_apis = SemanticApi.live.find :all
    @internal_videos = Video.related_to_video_segments(@video_segment.id)
    @segment_index = params[:segment_index]

    @external_contents_by_content_type_id =
      @video_segment.external_contents.active.with_weighted_score.include_content_sources.
      include_semantic_api.ordered_for_admin.by_content_type
    @external_contents_by_content_type_id.each do |key, contents|
      ExternalContent.filter_collection contents, @video_segment.live_topics_data
    end

    @thumb_config ||= APP_CONFIG[:thumbnails][:default]

    respond_to do |format|
      format.html
      format.json do
        render :json => {
          :status => 'success',
          :html => render_to_string(:partial => 'edit')
        }
      end
    end
  end

  def create
    return activescaffold_create unless params[:video_segment] || nil

    params[:video_segment][:video_id] ||= params[:video_id]
    @video_segment = VideoSegment.new! params[:video_segment]
    if @video_segment.save!
      flash[:notice] = "Video segment created."
      redirect_to :controller => 'admin/videos', :id => params[:video_id], :action => 'segment'
    else
    end
  end

  def update
    unless params[:video_segment] || nil
      return activescaffold_update
    end

    @video_segment = VideoSegment.find_by_id params[:id]
    if @video_segment.update_attributes! params[:video_segment]
      flash[:notice] = "Video segment updated."
      redirect_to :controller => 'admin/videos', :id => params[:video_id], :action => 'segment'
    else
    end
  end

  # Omit supplied topic id's from the results, to prevent topics that are already in the segment's topics
  # from appearing again. Could also do this on the client, but it's easier to just
  # do it here and not generate the HTML back to the client, rather than making the client parse through
  # a potential large amount of HTML.
  def suggested_topics
    @topic_video_segments = Topic.fetch_suggested_topics params[:transcript], params[:omit_topics]
    # Generate the form object here since we are directly rendering the partial
    @segment_index = params[:segment_index]
    respond_to do |format|
      format.json do
        render :json => {
          :status => 'success',
          :html => render_to_string(:partial => 'suggested_topics')
        }
      end
    end
  end

  # Reload (refresh) existing external content from DB
  def external_contents
    @video_segment = VideoSegment.find_by_id params[:id]
    @segment_index = params[:segment_index]
    @content_type = ContentType.find_by_id params[:content_type_id]
    @contents = ExternalContent.active.with_weighted_score.ordered_for_admin.scoped_by_content_type_id(params[:content_type_id]).
      scoped_by_video_segment_id(params[:id])
    ExternalContent.filter_collection @contents, @video_segment.live_topics_data
    respond_to do |format|
      format.json do
        render :json => {
          :status => 'success',
          :html => render_to_string(:partial => 'external_content')
        }
      end
    end
  end

  # Query API's for provisional external content given a transcript and content_type.
  # The video segment doesn't necessarily exist yet.
  def query_external_contents
    @segment_index = params[:segment_index]
    @content_type = ContentType.find_by_id params[:content_type_id]

    omit_identifiers = {}
    params[:omit_identifiers].each do |identifier|
      omit_identifiers[identifier] = true
    end if params[:omit_identifiers] && !params[:omit_identifiers].empty?

    @contents = VideoSegment.query_external_contents(
      params[:title],
      params[:transcript],
      params[:topics].values, {
        # ID of zero is passed in when video segment is provisional
        :id => (params[:id] || 0) != 0 ? params[:id] : nil,
        :content_type_id => params[:content_type_id],
        :omit_identifiers => omit_identifiers})
    respond_to do |format|
      format.json do
        render :json => {
          :status => 'success',
          :html => render_to_string(:partial => 'external_content')
        }
      end
    end

  end

end
