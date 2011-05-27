class Api::V1::TopicsController < Api::V1::ApiController

  def index
    @resources = Topic.live
    @resources = @resources.featured if (params[:featured] || nil) == 'true'

    @sort = params[:sort]
    case params[:sort] || nil
    when 'newest'
      @resources = @resources.order('created_at DESC')
    when 'popular'
      @resources = @resources.group('topics.id').
        videos_available.with_video_count.order('video_count DESC')
    else
      @sort = 'alpha'
      @resources = @resources.ordered
    end

    respond do |resources|
      {:topics => resources.map{|r| @template.topic_api_response_object(r, params)}}
    end
  end

  def show
    @resource = Topic.live.find params[:id]
    respond do |resource|
      {:topic => @template.topic_api_response_object(resource, params)}
    end
  end

  def search
    @resources = do_search Topic do |query|
      query.keywords params[:q], :query_phrase_slop => 1, :minimum_match => 1
      query.with(:live, true)
      case params[:sort] || nil
      when 'alpha'
        query.order_by(:name, :asc)
      else
        # Default: relevance
        @sort = 'relevance'
      end
    end

    respond do |resources|
      {:topics => resources.map{|r| @template.topic_api_response_object(r, params)}}
    end
  end

end
