module Admin::VideoSourcesHelper

  def video_source_videos_column record
    record.videos.count
  end

  def video_source_imported_videos_column record
    record.imported_videos.count
  end
  
end
