module Admin::VideoSegmentsHelper
  
  def video_segment_start_time_column record
    format_time record.start_time
  end

end
