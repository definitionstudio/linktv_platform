module ImagesHelper

  def thumbnail_path image, args = {}
    thumbnail_url image, args.merge({:only_path => true})
  end
  
  def thumbnail_url image, args = {}
    params = {}
    [:width, :height, :rw, :rh, :grow, :crop, :mask, :desaturate].each do |key|
      if args[key]
        params[key] = args[key]
      elsif APP_CONFIG[:thumbnails][:default][key].present?
        params[key] = APP_CONFIG[:thumbnails][:default][key]
      end
    end

    options_str = params.collect{|k, v| "#{k}=#{v}"}.join(',')

    if image.nil?
      sig = md5_signature image_not_available_path(args)
      path = (args[:only_path] || nil) ? image_not_available_path(args) : image_not_available_url(args)
      path = path + "?sig=#{sig}"
    else
      options = {
        :base_dir => image.base_dir, :id => image.id, :options => options_str,
        :format => args[:format] || APP_CONFIG[:thumbnails][:format] || :jpg
      }
      path = image_thumbnail_path options
      sig = md5_signature image_thumbnail_path(options)
      options[:only_path] = args[:only_path] || nil
      options[:host] = args[:host] if args[:host].present?
      path = image_thumbnail_url(options) + "?sig=#{sig}"
    end

    path
  end
  
  def non_resource_thumbnail_path url, args = {}
    non_resource_thumbnail_url url, args.merge({:only_path => true})
  end

  def non_resource_thumbnail_url uri, args = {}
    require 'open-uri'
    require 'digest/md5'
    
    args[:format] = APP_CONFIG[:thumbnails][:format]

    digest = Digest::MD5.hexdigest "#{uri}-#{args.inspect}"
    filename = "#{digest}.#{args[:format]}"

    pathname = File.join(IMAGE_CACHE_ROOT, filename)
    unless File.exists? pathname
      # Local cached version doesn't exist, create it
      Image.thumbnail uri, args.merge!({:cache_pathname => pathname})
    end

    cached_image_path :filename => digest, :format => args[:format], :only_path => (args[:only_path] || nil)
  end

  def image_not_available_path args = {}
    image_not_available_url args.merge({:only_path => true})
  end

  def image_not_available_url args = {}
    non_resource_thumbnail_url Image.image_not_available_path, args
  end

  def thumbnail_html image, args = {}
    args = args.merge({:grow => 1, :crop => :center}) # defaults
    path = thumbnail_path(image, args)
    attribution = image.nil? ? nil : image.attribution
    image_tag path, :alt => args[:alt].present? ? args[:alt] : nil, :title => args[:title].present? ? args[:title] : attribution
  end
  safe_helper :thumbnail_html

  # Thumbnails that have not yet been generated will have a placeholder image
  # and will be replaced dynamically in JS
  def dynamic_thumbnail_html image, args = {}
    path = thumbnail_path(image, args)

    # If the image doesn't exist, use the placeholder
    # and schedule a download for the next time
    if image.nil?
      return image_tag image_not_available_path(args)
    elsif !image.exists?
      if DEVELOPMENT_MODE
        image.download
      else
        image.send_later(:download)
      end
      return image_tag image_not_available_path(args) unless image.exists?
    end

    # Display a placeholder, and generate a URL to auto-gen the wanted thumbnail
    html = image_tag thumbnail_url(nil, args),
      :height => args[:height], :width => args[:width],
      :class => (['dynamic-img', 'dynamic-img-do-init'] << (args[:class] || nil)).join(' '), :alt => ''
    html += "<div style=\"display: none\" class=\"dynamic-img-src\">#{path}</div>".html_safe
  end
  safe_helper :dynamic_thumbnail_html

end
