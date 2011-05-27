class Admin::VideoSourcesController < Admin::AdminController

  active_scaffold :video_sources do |config|
    config.label = "Video Sources"
    config.actions.add :delete
    config.list.columns =
      [:name, :description, :feed_url, :videos, :imported_videos, :active]
    config.create.columns = config.update.columns =
      [:name, :description, :feed_url, :auth_username, :auth_password,
      :auto_accept_videos, :active]
    config.update.columns.add :deleted
    config.show.columns =
      [:name, :description, :feed_url, :auth_username, :videos,
      :auto_accept_videos, :active, :deleted, :created_at, :updated_at]
    config.action_links.add 'update_feed', :label => 'Update Feed', :type => :member, :position => false,
      :parameters => {:controller => 'admin/video_sources'}, :action => 'update_feed', :method => :post
    config.columns[:auto_accept_videos].form_ui = :checkbox
    config.columns[:active].form_ui = :checkbox
    config.columns[:deleted].form_ui = :checkbox
  end
  
  include Admin::DeletedInactiveFilters

  def update_feed
    @video_source = VideoSource.find params[:id]

    if !@video_source.active?
      flash[:error] = "Video source is inactive."
      redirect_to admin_video_sources_path
      return
    end

    if !@video_source.has_feed?
      flash[:error] = "Video source does not have an associated feed."
      redirect_to admin_video_sources_path
      return
    end

    new_items, total_items = @video_source.update_feed
    if (total_items == 0)
      notice = "Feed currently has no items"
    elsif (new_items == 0)
      notice = "No new items of #{total_items} total from feed."
    else
      notice = "Added #{new_items} new out of #{total_items} items from feed."
    end

    # update Active Scaffold row (must set @record first)
    @record = @video_source
    response = render_to_string :action => 'update_row'
    response += "\nalert('#{notice}');"
    
    respond_to do |format|
      format.js {
        render :js => response
      }
    end
  end

  # TODO require expiration and signature if disabling auth
  #skip_before_filter :authorize_admin, :only => :update_feeds
  protect_from_forgery :except => :update_feeds
  def update_feeds
    output = VideoSource.update_feeds
    response.content_type = "text/plain"
    render :inline => output, :layout => false
  end

end
