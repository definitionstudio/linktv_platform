# Intercept thumbnail requests and handle them if possible without invoking Rails

class Thumbnailer
  include ThumbnailGenerator
  
  def initialize app
    @app = app
  end

  def call env
    str = "/images/image_cache/"
    unless env['PATH_INFO'][0, str.length] == str
      return @app.call env
    end

    # Validate signature
    sig = env['QUERY_STRING'].match(/sig=(\w+)/)[1] rescue nil
    exp_sig = md5_signature env['PATH_INFO']
    raise Exceptions::HTTPBadRequest if exp_sig != sig

    # Example URL
    # http://localhost:3000/images/image_cache/base-33000/33589/thumbnail.mask=1,width=60,min=1,height=60,crop=center.png?sig=0877966fa5d0d9879ec77da5a6079450
    matches = env['PATH_INFO'].match /^(\/images\/image_cache\/((base-\d+)\/(\d+))\/(thumbnail\.([^\.]+)\.(png|jpg)))$/

    unless matches.present? && matches.length == 8
      return @app.call env
    end

    cache_path = matches[1]
    dir_path = matches[2]
    filename = matches[5]
    args = HashWithIndifferentAccess[*(matches[6].split(',').collect{|i| [i.split('=')]}.flatten)]
    format = matches[7]

    # Should see only one file in the media directory
    # If not, we'll defer to the rails app which might be able to download it
    files = Dir[File.join PRIVATE_IMAGES_ROOT, "#{dir_path}/*"]
    unless files.length == 1
      return @app.call env
    end
    uri = files.first

    args.merge!({
      :format => format,
      :cache_pathname => File.join(IMAGE_CACHE_ROOT, dir_path, filename)
    })

    begin
      thumb = self.class.thumbnail uri, args
    rescue => exc
      return @app.call env
    end

    return @app.call env if thumb.nil?
    return [200, {"Content-type" => "image/#{format}"}, [thumb]]
  end

end
