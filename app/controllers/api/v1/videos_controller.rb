class Api::V1::VideosController < Api::V1::ApiController

  helper :images, :topics, :videos, :video_segments, 'api/v1/topics'

  def index
    @resources = Video.available
    @resources = @resources.featured if (params[:featured] || nil) == 'true'

    # TODO: this may not be completely DRY against the main videos_controller
    if params[:topics] || nil
      topic_ids = Topic.live.scoped_by_id(params[:topics].split(','))
      @resources = @resources.related_to_all_topics(topic_ids)
    else
      @resources = @resources.default_scoring
    end
    
    if params[:regions] || nil
      @resources = @resources.regions_id_eq(params[:regions].split(','))
    end

    @sort = params[:sort]
    case params[:sort] || nil
    when 'alpha'
      @resources = @resources.order('name')
    when 'newest'
      @resources = @resources.order('published_at DESC')
    else
      # Default: relevance
      @sort = 'relevance'
      @resources = @resources.order('score DESC')
    end

    respond do |resources|
      {:videos => resources.map{|r| @template.video_api_response_object(r, params)}}
    end

  end

  def show
    @resource = Video.available.find params[:id]
    respond do |resource|
      {:video => @template.video_api_response_object(resource, params)}
    end
  end

  def search
    @resources = do_search Video do |query|
      query.keywords params[:q], :query_phrase_slop => 1, :minimum_match => 1
      query.with(:available, true)
      case params[:sort] || nil
      when 'alpha'
        query.order_by(:name, :asc)
      when 'newest'
        query.order_by(:published_at, :desc)
      else
        # Default: relevance
        @sort = 'relevance'
      end
    end

    respond do |resources|
      {:videos => resources.map{|r| @template.video_api_response_object(r, params)}}
    end
  end

end
