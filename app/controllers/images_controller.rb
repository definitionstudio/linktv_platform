class ImagesController < FrontEndController

  def thumbnail
    # Double-checking supported image formats, but should already be masked by routes
    raise Exceptions::HTTPBadRequest if params[:format] !~ /png|jpg/

    # Verify the URL is authentic
    path = request.env['PATH_INFO']
    sig = md5_signature path
    raise Exceptions::HTTPBadRequest if params[:sig] != sig

    # Parse options in the format: thumbnail.key=value,key2=value2.format
    options = HashWithIndifferentAccess[*(params[:options].split(',').
      collect{|i| [i.split('=')]}.flatten)]
    options[:format] = params[:format]

    begin
      @image = Image.find params[:id]
      raise Exceptions::HTTPNotFound if @image.nil?

      # Download image if necessary
      raise "Image download failed" unless @image.download

      thumb = @image.thumbnail options
    rescue => exc
      logger.error exc.inspect
    end

    if thumb.nil?
      # load default image
      thumb = Image.thumbnail Image.image_not_available_path, options
    end

    # This exception should only happen if we couldn't generate the "not available" image
    # It is not expected.
    raise Exceptions::HTTPInternalServerError if thumb.nil?

    case params[:format].to_sym
    when :png
      send_data thumb, :type => "image/png", :disposition => 'inline'
    when :jpg, :jpeg
      send_data thumb, :type => "image/jpeg", :disposition => 'inline'
    end

  end

end
