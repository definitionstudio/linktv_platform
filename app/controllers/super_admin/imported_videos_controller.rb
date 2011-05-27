class SuperAdmin::ImportedVideosController < SuperAdmin::SuperAdminController

  active_scaffold :imported_videos do |config|
    config.label = 'Imported Videos'
    config.columns[:video_source].form_ui = :select
    config.list.columns = config.create.columns = config.update.columns =
      [:name, :link, :video_source, :notes, :status]
    config.show.columns =
      [:name, :source_published_at, :link, :video_source, :status, :created_at, :updated_at]
  end

end
