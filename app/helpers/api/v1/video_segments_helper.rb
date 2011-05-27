module Api::V1::VideoSegmentsHelper

  def video_segment_api_response_object video_segment, params = {}
    data = {
      :id => video_segment.id,
      :name => video_segment.name,
      :start_time => video_segment.start_time,
      :thumbnail_url => video_segment.thumbnail.present? ?
        thumbnail_url(video_segment.thumbnail, {:width => 75, :height => 56, :crop => 1}) : '',
      :thumbnail_url_lg => video_segment.thumbnail.present? ?
        thumbnail_url(video_segment.thumbnail, {:width => 400, :height => 300, :crop => 1}) : '',
    }

    if (params[:return_transcript] || nil) == 'true'
      data[:transcript_text] = video_segment.transcript_text
    end

    data
  end

end
