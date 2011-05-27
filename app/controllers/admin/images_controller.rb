class Admin::ImagesController < Admin::AdminController

  before_filter :find_image, :only => [:show]
  def find_image
    @image = Image.find params[:id]
    raise Exceptions::HTTPNotFound if @image.nil?
  end
  protected :find_image

  helper :images

  def show
    file = open @image.pathname
    send_data file.read, :type => "image/png", :disposition => 'inline'
  end

  def create
    # Note: The ajaxupload.js doesn't proreply return JSON, at least in Firefox 3.6
    begin
      raise "No filename received" unless params[:filename]
      raise "No image data received" unless params[:image]
      raise "Invalid file type" unless (params[:image].content_type rescue nil) =~ /^image\/jpeg|image\/png$/

      image = Image.create! :filename => params[:filename]
      image.write params[:image].read

      respond_to do |format|
        format.xml {
          render :xml => {:status => 'success', :id => image.id, :src => @template.thumbnail_url(image)}
        }
      end
    rescue => error
      respond_to do |format|
        format.xml {
          render :xml => {:status => 'error', :message => error.to_s}, :status => :bad_request
        }
      end
    end

  end

end
