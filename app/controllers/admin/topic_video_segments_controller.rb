class Admin::TopicVideoSegmentsController < Admin::AdminController

  def new
    @topic = Topic.new params[:topic]
    @entity_dbs = EntityDb.live
    @topic.fill_entity_identifiers
    @matching_topics = Topic.matching_topics((params[:topic][:name] rescue nil), (params[:omit] || nil))
    @allow_existing_topics = true
    render :json => {
      :html => render_to_string(:partial => 'admin/topics/new', :locals =>
          {:url => admin_topic_video_segments_path})
    }
  end

  def create
    @topic = Topic.new params[:topic]
    unless @topic.save
      respond_to do |format|
        format.json {
          render :json => {
            :status => :invalid
          }
        }
      end
      return
    end

    # Creating a new topic that might be linked to a segment if the segment is saved.
    # Create a provisional topic_video_segment link and return the HTML form for saving
    @topic_video_segment = TopicVideoSegment.new({
      :topic => @topic,
      :score => params[:score] || nil
    })
    @segment_index = params[:segment_index]

    respond_to do |format|
      format.json {
        render :json => {
          :status => :created,
          :html => render_to_string(:partial => 'admin/topics/create.haml',
            :locals => {:video_segment => @video_segment, :segment_index => @segment_index,
            :topic_video_segment => @topic_video_segment})
        }
      }
    end
  end
end
