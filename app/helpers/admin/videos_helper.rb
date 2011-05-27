module Admin::VideosHelper

  def video_name_column record
    link_to record.name, edit_admin_video_path(record.id)
  end

  def video_duration_column record
    format_time record.duration
  end

  def video_status_column record
    record.status.to_s.titleize
  end

  def video_video_segments_column record
    record.video_segments.count
  end

  def video_video_files_column record
    record.video_files.count
  end

  def published_status_css_class record
    record.published ? 'video-status video-published-status' : 'video-status video-unpublished-status'
  end

	def status_css_class record
		'video-status video-status-' + record.status.to_s
	end

  # TODO
  # This is an example of code to produce object map data in JSON for the browser.
  def o_data_video_topics topics
    data = {:index => {}, :list => []}
    topics.each do |topic|
      topic_data = {
        :id => topic.id,
        :name => topic.name,
        :html => {
          :topic_with_identifiers =>
            render_to_string(:partial => 'admin/topics/topic_with_identifiers.haml',
              :locals => {:topic => topic})
        }
      }
      data[:list] << topic.id
      data[:index][topic.id] = topic_data
    end
    data
  end

end
