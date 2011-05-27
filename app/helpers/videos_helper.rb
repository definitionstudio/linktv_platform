module VideosHelper
  
  def videos_parameters current_params, args = {}
    params = {}
    unless current_params.nil? || current_params.empty?
      # Ensure args are keyed by symbols
      current_params.each{|k, v| params[k.to_sym] = v}
    end

    args[:topics] = [args[:topic]] if args[:topic].present?
    if args[:topics] || nil
      # Override existing topics
      params.delete :t
      params.delete :tx
      params.delete :tn
      if args[:topics].empty?
      elsif args[:topics].length == 1
        params[:t] = args[:topics][0].permalink
      else
        params.delete :t
        params[:tx] = Topic.obfuscate_topic_ids(args[:topics].collect{|t| t.id})
      end

    elsif args[:toggle_topic].present?
      topic_id = args[:toggle_topic].id
      if params[:t].present?
        topic = Topic.live.find_by_permalink params[:t]
        topic_ids = topic.present? ? [topic.id] : []
      elsif params[:tx].present?
        topic_ids = Topic.deobfuscate_topic_ids(params[:tx])
      else
        topic_ids = []
      end

      # Remove or add the topic
      topic_ids.delete(topic_id) || topic_ids << topic_id

      if topic_ids.empty?
        params.delete :t
        params.delete :tx
      elsif topic_ids.length == 1
        # Replace with permalink
        params[:t] = Topic.live.find_by_id(topic_ids[0]).permalink
        params.delete :tx
      else
        params.delete :t
        params[:tx] = Topic.obfuscate_topic_ids(topic_ids)
      end
    end

    # Process secondary topics
    if params[:tn].present?
      secondary_topic_ids = Topic.deobfuscate_topic_ids(params[:tn])
    else
      secondary_topic_ids = []
    end
    if args[:toggle_secondary_topic].present?
      secondary_topic_id = args[:toggle_secondary_topic].id
      # Remove or add the topic
      secondary_topic_ids.delete(secondary_topic_id) || secondary_topic_ids << secondary_topic_id
      unless secondary_topic_ids.empty?
        params[:tn] = Topic.obfuscate_topic_ids secondary_topic_ids
      else
        params.delete :tn
      end
    else
      # Topic narrowing is only supported in the secondary topic menu
      # Note: not anymore, looks like...
      #params.delete :tn
    end

    args[:region_ids] = [args[:region]] if args[:region].present?
    region_ids = []
    if args[:clear_regions] || nil
      region_ids = []
      params.delete :r
    elsif args[:region_ids].present?
      region_ids = args[:region_ids] unless args[:region_ids].empty?
    elsif args[:region_ids] || nil
      # Must be empty
      region_ids = []
    else
      region_ids = parse_csv(params[:r]).collect{|x| x.to_i} if params[:r].present?
      if args[:toggle_region].present?
        if params[:r].present?
          region_ids = parse_csv(params[:r]).collect{|x| x.to_i}
        else
          region_ids = []
        end
        region_id = args[:toggle_region].id
        # Remove or add the topic
        region_ids.delete(region_id) || region_ids << region_id
      end
    end
    if region_ids.empty?
      params.delete :r
    else
      params[:r] = region_ids.reverse.collect{|id| id.to_s}.join(',')
    end

    # Allow nil to override
    if args.include? :page
      if args[:page].nil?
        params.delete :page
      else
        params[:page] = args[:page].to_i
      end
    end

    if args[:view].present?
      params[:view] = args[:view]
    elsif sticky_params[:view].present?
      params[:view] = sticky_params[:view]
    end

    if args[:order_by].present?
      params[:order_by] = args[:order_by]
    elsif args[:order_by] || nil
      params.delete :order_by
    end

    return nil if params.empty?
    query_params_string(params)
  end

  #
  # Generate a new video index path
  # If current_params is not nil, they will be a starting point and args will be supplied to refine the path.
  #
  def parameterized_videos_path current_params, args = {}
		parameterized_videos_path_data(current_params, args)[:path]
	end

  def parameterized_videos_path_data current_params, args = {}
    params = videos_parameters(current_params, args)
    path = videos_path
    path += ".#{args[:format]}" if args[:format].present?

    path = [path, params].join('?') unless params.nil? || params.empty?
    {
			:path => path,
			:params => params
		}
  end
  
  def video_thumbnail_html video, args = {}
    args[:class] ||= []
    args[:class] = args[:class].join(' ') if args[:class].is_a? Array
    args = args.merge({
      :class => "video-thumbnail #{args[:class]}",
      :alt => (video.nil? ? nil : video.name),
      :width => args[:width],
      :height => args[:height],
      :crop => :center})
    if args[:dynamic] || nil
      dynamic_thumbnail_html(video.nil? ? nil : video.thumbnail, args)
    else
      thumbnail_html(video.nil? ? nil : video.thumbnail, args)
    end
  end
  safe_helper :video_thumbnail_html

  def video_rss_keywords video
    video.topics.live.order('score DESC').limit(10).collect{|t| t.name}.join(', ')
  end

  def restricted_video_message
    "Media for this video is not available in your region."
  end

  def to_timecode seconds
    hours = seconds.to_i / 3600
    minutes = seconds.to_i % 3600 / 60
    seconds = seconds.to_i % 60
    timecode = (minutes < 10 ? '0' : '') + minutes.to_s + ':' + (seconds < 10 ? '0' : '') + seconds.to_s;
    timecode = (hours < 10 ? '0' : '') + hours.to_s + ':' + timecode if hours > 0
    timecode
  end

  def embed_code video, args = {}
    src = args[:host].present? ? video_url(video.permalink, :host => args[:host]) : video_url(video.permalink)
    "<iframe width=\"#{APP_CONFIG[:video][:embedded_player][:width]}\" height=\"#{APP_CONFIG[:video][:embedded_player][:height]}\" src=\"#{src}/player\" frameborder=\"0\" scrolling=\"no\"></iframe>"
  end

end
