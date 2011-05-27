module Admin::ImportedVideosHelper

  def imported_video_name_column record
    link_to record.name, edit_admin_imported_video_path(record)
  end

  def published_status_css_class record
    nil
  end

	def status_css_class record
		'video-status video-status-' + record.status.to_s
	end

end
