module Admin::VideoFilesHelper
  
  def video_file_status_column record
    record.status.to_s.titleize
  end

end
