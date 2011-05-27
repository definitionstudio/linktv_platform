module Api::V1::VideosHelper

  def video_api_response_object video, params = {}
    data = {
      :id => video.id,
      :name => video.name,
      :url => video_url(video.permalink, :host => APP_CONFIG[:site][:host]),
      :duration => video.duration,
      :description => video.description,
      :publish_date => video.published_at.to_s(:rfc822),
      :thumbnail_url_sm => video.thumbnail.present? ? 
        thumbnail_url(video.thumbnail, {:host => APP_CONFIG[:site][:host], :width => 100, :height => 75, :crop => 1}) : '',
      :thumbnail_url_lg => video.thumbnail.present? ?
        thumbnail_url(video.thumbnail, {:host => APP_CONFIG[:site][:host],:width => 480, :height => 360, :crop => 1}) : '',
      :embed_code => embed_code(video, {:host => APP_CONFIG[:site][:host]})
    }

    if (params[:return_transcript] || nil) == 'true'
      data[:transcript_text] = video.transcript_text
    end

    if (params[:return_topics] || nil) == 'true'
      data[:topics] = Topic.live.group('topics.id').
        videos_available.related_to_videos(video.id).order('score DESC').
        map{|t| topic_api_response_object(t, params)}
    end

    if (params[:return_chapters] || nil) == 'true'
      data[:chapters] = video.video_segments.live.ordered.
        map{|s| video_segment_api_response_object(s, params)}
    end

    data
  end

end
