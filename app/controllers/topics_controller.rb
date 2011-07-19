class TopicsController < FrontEndController

  helper :videos, :video_segments, :images

  def index

    # process order_by params
    @order_bys = [
      {:name => 'A-Z', :value => 'a-z', :title => 'View alphabetically'},
      {:name => 'Popular', :value => 'popular', :title => 'View topics with more videos first'},
      {:name => 'Newest', :value => 'newest', :title => 'View topics with the newest videos first'}
    ]

    # default
    @order_by = :'a-z'
    @order_by_name = "A-Z"
    
    param_order_by = params[:order_by] || ''
    @order_bys.each do |order_by|
      if order_by[:value] == param_order_by.downcase
        @order_by = order_by[:value].to_sym
        @order_by_name = order_by[:name]
        break
      end
    end

    @page_title = "Topics - #{@page_title}"
    
    @topics = Topic.live.group('topics.id').videos_available.with_video_count
    @topics = @topics.order_by(@order_by).include_entity_identifiers.paginate(
      :page => (params[:page] || 1),
      :per_page => params[:per_page] || APP_CONFIG[:pagination][:videos][:per_page]
    )

    @page_params = {}
    [:q, :view, :order_by, :page, :index].each do |key|
      @page_params[key] = params[key] if params[key].present?
    end

    # output
    if request.xhr?
      respond_to do |format|
        format.json {
          render :json => {
            :status => 'success',
            :html => render_to_string(:partial => 'topics/index')
            }
          }
      end
    end
    
  end

  def show

    @topic = Topic.live.scoped(:conditions => ['topics.guid = ? OR topics.permalink = ?', params[:identifier], params[:identifier]])
    @topic = @topic.first
    
    raise Exceptions::HTTPNotFound if @topic.nil?

    @page_title = "#{@topic.name} - #{@page_title}"

    @related_videos =
      Video.available.
      related_to_topics(@topic.id).
      order('score DESC')

    @related_topics =
      Topic.live.group('topics.id').
      related_to_topics(@topic.id).
      videos_available.
      order('score DESC')

    respond_to do |format|
      format.html
      format.rdf {render :action => 'show.rdf.erb', :layout => false}
    end
    
  end

  def autocomplete
    if params['q'].nil? || params['q'].empty?
      render :nothing => true
      return
    end

    current_params = {}
    CGI.parse(params[:current_params]).each{|k, v| current_params[k] = v.last}

    data = []
    topics = Topic.live.group('topics.id').
      videos_available.
      with_video_count.
      live.name_like(params['q']).
      limit(10).order('sort_name')
    topics.each do |topic|
      data << {
        'permalink' => topic.permalink,
        'url' => @template.parameterized_videos_path(current_params, :topic => topic, :page => nil),
        'label' => topic.name,
        'description' => topic.description || ''
      }
    end

    result = {
      :status => 'success',
      :data => data
    }

    respond_to do |format|
      format.json {
        render :json => result
      }
    end

  end

end
