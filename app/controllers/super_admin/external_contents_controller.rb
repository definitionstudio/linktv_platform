class SuperAdmin::ExternalContentsController < SuperAdmin::SuperAdminController

  active_scaffold :external_contents do |config|
    config.label = "External Content"
    config.list.columns =
      [:name, :description, :video_segment, :content_type, :semantic_api, :score,
        :published_at, :expires_at, :active, :deleted]
    config.show.columns =
      [:name, :description, :url, :video_segment, :content_type, :semantic_api, :score,
        :published_at, :expires_at, :active, :deleted, :created_at, :updated_at]
    config.create.columns = config.update.columns =
      [:name, :description, :url, :video_segment, :content_type, :semantic_api, :score,
        :published_at, :expires_at, :active, :deleted]

    config.columns[:video_segment].form_ui = :select
    config.columns[:content_type].form_ui = :select
    config.columns[:semantic_api].form_ui = :select
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters
  
end
