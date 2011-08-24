class VideosController < FrontEndController

  before_filter :find_video, :only => [:show, :player, :register_play]
  
  def find_video
    @video = Video.live.published_now.find_by_permalink params[:id]
    raise Exceptions::HTTPNotFound if @video.nil?
  end
  protected :find_video

  helper :images, :topics, :videos, :video_segments, :external_contents

  def index

    # redirect output for RSS
    return index_rss if (params[:format] || nil) == 'rss'

    # process order_by params
    @order_bys = [
      {:name => 'Recommended', :value => 'recommended', :title => 'Sort with most recommended videos first'},
      {:name => 'Relevance', :value => 'relevance', :title => 'Sort by relevance'},
      {:name => 'Newest', :value => 'newest', :title => 'Sort with newest videos first'},
      {:name => 'A-Z', :value => 'a-z', :title => 'Sort alphabetically'},
    ]

    # default
    @order_by = :recommended
    @order_by_name = "Recommended"

    param_order_by = params[:order_by] || ''
    @order_bys.each do |order_by|
      if order_by[:value] == param_order_by.downcase
        @order_by = order_by[:value].to_sym
        @order_by_name = order_by[:name]
        break
      end
    end

    @page_title = "Videos - #{@page_title}"

    # Load selected, paginated videos, narrowing if necessary
    load_videos
    @paginated_videos = @videos.include_thumbnail.order_by(@order_by).paginate :all,
      :page => params[:page] || 1, :per_page => params[:per_page] || APP_CONFIG[:pagination][:videos][:per_page]

    # load featured topics
    @featured_topics = Topic.live.group('topics.id').featured.videos_available.with_video_count
    @featured_topics.each{|t| t.is_selected = true if @primary_topic_ids.include? t.id}

    # load related topics
    if @primary_topic_ids.empty?
      @related_topics = []
    else
      @related_topics =
        Topic.live.group('topics.id').
        related_to_topics(@primary_topic_ids).
        videos_available.
        scoped(:conditions => ["topics.id NOT IN(?)", @filtered_topic_ids]).
        order('video_count DESC').limit(10)
    end

    # load regions
    @regions = Region.all

    # output
    if request.xhr?
      respond_to do |format|
        format.json {
          render :json => {
            :status => 'success',
            :html => render_to_string(:partial => 'index', :layout => false)
            }
          }
      end
    end
  end

  def sitemap
    
    #clear all params
    params = {}

    load_videos

    # TODO: not preloading topics here due to score filtering (OPTIMIZATION)
    @videos = @videos.order('published_at DESC').scoped(:include => [:thumbnail]).all

    response.headers["Content-Type"] = "application/xml"
    render 'videos/sitemap.xml.erb', :layout => false

  end

  def show

    @start = (params[:start] || 0).to_i
    @video_segments = @video.video_segments.live.ordered
    @video_segments.each do |segment|
      segment.load_contents_data
      # Select the active video segment based on start time
      @video_segment = segment if @start >= segment.start_time
    end
    @video_segment = @video_segments.first if @video_segment.nil?   # default to first segment if time lookup fails
    @segment_contents_tabs = %w(related-videos related-articles actions)

    @page_title = "#{@video.name}" + " - #{@page_title}"
    @more_info = @video.resource_attr_by_name 'more_info'

    # Be sure a least one segment is selected, even with an arbitrary start time being supplied
    raise "Video contains no video segments" if  @video_segments.empty?

    @related_topics = Topic.live.group('topics.id').videos_available.
      related_to_videos(@video.id).public.scoped(:order => 'score DESC')

    @player_options = APP_CONFIG[:video]
    @video_files = @video.get_video_files(request_country)

    respond_to do |format|
      format.html do
        # Schedule fetch of content for all segments in background if necessary
        @video_segment_preload = @video.check_external_contents @video_segment.id, :block => false
      end
      format.rdf {render :action => 'show.rdf.erb', :layout => false}
    end
  end

  def player
    # No caching - depends on request IP address/country
    expires_now

    @video_segments = @video.video_segments.live.ordered
    @more_info = @video.resource_attr_by_name 'more_info'

    @video_files = @video.get_video_files(request_country)  # smallest first
    @player_options = APP_CONFIG[:video]
    @show_segment_contents = (params[:related] || nil) == 'true'

    unless @video.unrestricted? request_country
      @message = @template.restricted_video_message
    end

    @player_type = request.xhr? ? (params[:type] || 'local') : 'embedded' # force 'embedded' for non-XHR requests
    if @player_type == 'embedded'
      @embedded_player_params = Hash[params.select{|k, v| [:size, :related].include?(k.to_sym)}].merge({:context => 'reload', :type => 'embedded'})
    end
    @start = (params[:start] || 0).to_i

    @video_segments.each do |segment|
      # Select the active video segment based on start time
      @video_segment = segment if @start >= segment.start_time
    end
    @video_segment = @video_segments.first if @video_segment.nil?

    init_player_config

    if request.xhr?
      if params[:context] == 'reload'
        render :json => {
          :status => 'success',
          :html => render_to_string(:partial => 'videos/video_player', :layout => false)
        }
      else
        render :json => {
          :status => 'success',
          :html => render_to_string(:layout => false)
        }
      end
    else
      respond_to do |format|
        format.html {
          # load EMBEDDED PLAYER container w/ajax load to call this action via XHR
          render :partial => 'videos/video_player', :layout => 'embedded_player'
        }
        format.json {
          # output player config JSON
          render :json => @player_config.to_json
        }
      end
    end
  end

  def swf
    # used for Google Video Sitemap video:player_loc
    redirect_to APP_CONFIG[:video][:embedded_player][:swf] + "?configUrl=#{CGI::escape(player_video_url)}.json"
  end

  # TODO: this request should be signed for authenticity
  skip_before_filter :verify_authenticity_token, :only => [:register_play]
  def register_play
    @video.register_play(
      :video_segment_id => params[:video_segment_id] || nil,
      :ip => request.ip,
      :http_user_agent => request.headers['HTTP_USER_AGENT'] || nil,
      :http_referer => request.headers['HTTP_REFERER'] || nil,
      :user_id => params[:user_id] || nil
    )
    render :json => {:status => 'success'}
  end

  protected

  include Linktv::Platform::VideoPlayer::ControllerMixin

  def parse_filter_params
    # Process primary topics
    # The union of all videos associated to these topics will be selected in the primary query
    primary_topic_ids = []
    if params[:t].present?
      # Single topic selected by permalink
      topic = Topic.find_by_permalink params[:t]
      primary_topic_ids = [topic.id] if topic.present?
    elsif params[:tx].present?
      primary_topic_ids = Topic.deobfuscate_topic_ids params[:tx]
    end

    # Toggle topic in response to user interaction with topic menu items
    if params[:toggle_topic].present?
      toggle_topic = Topic.find_by_permalink params[:toggle_topic]
      if toggle_topic.present?
        primary_topic_ids.delete(toggle_topic.id) || primary_topic_ids.push(toggle_topic.id)
      end
    end

    # Region parameters
    @region_ids = params[:r].present? ? parse_csv(params[:r]).collect{|x| x.to_i} : []
    @regions = @region_ids.empty? ? [] : Region.find_all_by_id(@region_ids)

    # Secondary "narrow by" topic parameters
    secondary_topic_ids = params[:tn].present? ? (Topic.deobfuscate_topic_ids params[:tn]) : []

    # Ensure all selected topics are live
    @primary_topics = primary_topic_ids.empty? ? [] : Topic.live.scoped_by_id(primary_topic_ids)
    @primary_topic_ids = @primary_topics.collect{|t| t.id}
    @secondary_topics = secondary_topic_ids.empty? ? [] : Topic.live.scoped_by_id(secondary_topic_ids)
    @secondary_topic_ids = @secondary_topics.collect{|t| t.id}
    @filtered_topic_ids = (@primary_topic_ids + @secondary_topic_ids).uniq

    # Isolate the existing params that persist in links
    @page_params = {}
    [:t, :tx, :tn, :r, :view, :order_by, :page].each do |key|
      @page_params[key] = params[key] if params[key].present?
    end
  end

  def load_videos
    if params[:t].present?
      # Single topic selected by permalink
      topic = Topic.find_by_permalink params[:t]
      raise Exceptions::HTTPNotFound if topic.nil?
      @page_title = "#{topic.name} #{@page_title}"
    end

    parse_filter_params

    # Load selected videos, narrowing if necessary
    @videos = Video.available
    @videos = @videos.regions_id_eq(@region_ids) unless @region_ids.empty?

    if @filtered_topic_ids.empty?
      @videos = @videos.default_scoring
    else
      # Require all topics to be matched by counting
      @videos = @videos.related_to_all_topics(@filtered_topic_ids)
    end
  end

  def index_rss

    load_videos

    @videos = @videos.order('published_at DESC').
      scoped(:include => [:video_files, :thumbnail, :topics]).
      limit((APP_CONFIG[:rss][:videos][:limit] rescue 15)).all

    @rss_settings = APP_CONFIG[:rss][:videos].dup
    @rss_settings[:pubDate] = @videos.count > 0 ? @videos[0].published_at : Time.now

    topics = (@primary_topics + @secondary_topics).sort {|a, b| a.name <=> b.name}
    unless topics.empty?
      @rss_settings[:description] += " (Filtered by topics: " + topics.collect{|t| t.name}.join(', ') + ")"
    end
    unless @regions.empty?
      @rss_settings[:description] += " (Filtered by regions: " + @regions.collect{|r| r.name}.join(', ') + ")"
    end

    respond_to do |format|
      format.rss {
        response.headers["Content-Type"] = "application/xml"
        render 'videos/index.rss.erb', :layout => false
      }
    end
  end

end
