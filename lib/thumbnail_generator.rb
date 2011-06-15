require 'extensions/gd2'
#require File.join(File.dirname(__FILE__), "..", "..", "lib", "gd2_ext.rb")

module ThumbnailGenerator

  def self.included base
    base.module_eval do

      # args[:height]
      # args[:width]
      # args[:rw] int 1 to respect target width
      # args[:rh] int 1 to respect target height
      # args[:grow] int 1 to allow image enlargement
      # args[:crop] string :center, TODO: additional options
      # args[:mask]
      # args[:desaturate]
      def self.thumbnail uri, args = {}
        args[:width] = (args[:width] || APP_CONFIG[:thumbnails][:default][:width]).to_i
        args[:height] = (args[:height] || APP_CONFIG[:thumbnails][:default][:height]).to_i
        args[:grow] ||= nil
        args[:rw] ||= nil
        args[:rh] ||= nil
        args[:desaturate] ||= nil
        args[:format] ||= APP_CONFIG[:thumbnails][:format]


        begin
          image = GD2::Image.load open(uri)
          image = image.to_true_color unless image.is_a? GD2::Image::TrueColor
        rescue => exc
          return nil
        end

        if !image
          return nil
        end

        image.alpha_blending = false
        image.save_alpha = true

        Rails.logger.debug "src dimensions: #{image.width}, #{image.height}"

        src_aspect = image.width.to_f/image.height.to_f
        target_aspect = args[:width].to_f/args[:height].to_f

        Rails.logger.debug "src aspect #{src_aspect}"
        Rails.logger.debug "target aspect #{target_aspect}"


        if args[:crop] && args[:crop].to_sym == :center

          Rails.logger.debug 'cropping image'

          if args[:width] > args[:height]  # width priority

            crop_width = image.width
            crop_height = image.width/target_aspect

          else

            crop_height = image.height
            crop_width = image.height*target_aspect

          end

          Rails.logger.debug "cropped dimensions: #{crop_width}, #{crop_height}"

          # :center (default)
          crop_x = (image.width - crop_width.to_i) / 2
          crop_y = (image.height - crop_height.to_i) / 2
          image.crop!(crop_x.to_i, crop_y.to_i, crop_width.to_i, crop_height.to_i)

          src_aspect = target_aspect

        end

        if args[:rw] || image.width > image.height  # horizontal size preference

          if !args[:grow] && image.width < args[:width]
            width = image.width
          else
            width = args[:width]
          end
          height = width / src_aspect

        else  # portrait or square image, height preference

          if !args[:grow] && image.height < args[:height]
            height = image.height
          else
            height = args[:height]
          end
          width = height * src_aspect

        end

        # correct any size overages
        if !args[:rh] && width > args[:width]

          width = args[:width]
          height = width / src_aspect

        elsif !args[:rw] && height > args[:height]

          height = args[:height]
          width = height * src_aspect

        end

        image.resize! width.to_i, height.to_i

        if args[:desaturate] || nil
          image = image.desaturate
        end

        if args[:mask] || nil
          if APP_CONFIG[:thumbnails][:mask].present?
            mask_path = File.join(RAILS_ROOT, 'public', APP_CONFIG[:thumbnails][:mask])
            if File.exists? mask_path
              mask_image = GD2::Image.import mask_path
              image.mask! mask_image
            end
          end
        end

        case args[:format].to_sym
        when :png
          thumb = image.png
        when :jpg, :jpeg
          thumb = image.jpeg(quality = APP_CONFIG[:thumbnails][:jpeg_quality])
        end

        if args[:cache_pathname].present?
          # Write out to a temporary file and rename once it's done to avoid race conditions with other requests
          dir = File.dirname args[:cache_pathname]
          FileUtils.mkdir_p dir unless File.exist?(dir)
          temp = "#{args[:cache_pathname]}.temp.#{Time.now.to_i}#{File.extname(args[:cache_pathname])}"
          image.export temp
          File.rename temp, args[:cache_pathname]
        end

        if thumb.nil?
          return nil
        end

        thumb
      end
    end
  end

end
