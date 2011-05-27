class Admin::ExternalContentsController < Admin::AdminController

  def new
    @external_content = ExternalContent.new params[:external_content]
    render :json => {
      :status => 'success',
      :html => render_to_string(:layout => false)
    }
  end

  def create
    @external_content = ExternalContent.new params[:external_content]

    provisional = params[:provisional] || nil

    if (provisional)
      valid = @external_content.valid?
    else
      valid = @external_content.save
    end

    unless valid
      render :action => :new, :layout => false
      return
    end

    flash[:notice] = "External content created." unless provisional
    html = nil
    if (params[:render_for] || nil) == 'external-content-table'
      html = render_to_string :partial => 'admin/video_segments/content_row_table', :locals => {
        :content => @external_content}
    end
    render :json => {
      :status => 'success',
      :html => html
    }
  end
  
end
