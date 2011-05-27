# Extensions to GD2
# Don't make these classes unloadable, since the gem versions are not. Otherwise the overrides get lost between accesses

require 'gd2'

module GD2

  class Color

    # Based on phpThumb-1.7.9:phpthumb.functions.php:GrasycaleValue
    def self.grayscale_value red, green, blue
      return (red * 0.3).round + (green * 0.59).round + (blue * 0.11).round
    end
    private_class_method :grayscale_value

    # Based on phpThumb-1.7.9:phpthumb.functions.php:GrasycalePixel
    def self.grayscale_pixel original_pixel
      gray = grayscale_value original_pixel.red, original_pixel.green, original_pixel.blue
      Color.new gray, gray, gray
    end

  end

  class Image::TrueColor

    def fill_rectangle x, y, w, h, color
      SYM[:gdImageFilledRectangle].call @image_ptr, x, y, w, h, color.to_i
    end

    # Based on phpThumb-1.7.9:phpthumb.filters.php:ApplyMask and gd2-1.1.1
    def mask! mask_image
      scaled_mask_image = mask_image.resize self.width, self.height

      mask_blendtemp = TrueColor.new self.width, self.height
      mask_blendtemp.alpha_blending = false
      mask_blendtemp.save_alpha = true

      (0...self.width).each do |idx_x|
        (0...self.height).each do |idx_y|
          real_pixel = self[idx_x, idx_y]
          mask_pixel = Color.grayscale_pixel scaled_mask_image[idx_x, idx_y]
          mask_alpha = 127 - ((mask_pixel.red.to_f / 2).floor * (1 - real_pixel.alpha.to_f / 127)).floor
          mask_blendtemp[idx_x, idx_y] = Color[real_pixel.red, real_pixel.green, real_pixel.blue, mask_alpha]
        end
      end

      self.alpha_blending = false
      self.save_alpha = true

      self.copy_from mask_blendtemp, 0, 0, 0, 0, self.width, self.height
      self
    end

    # Based (loosly!) on phpThumb-1.7.9:phpthumb.filters.php:Colorize()
    def desaturate
      image = TrueColor.new self.width, self.height
      (0...self.width).each do |idx_x|
        (0...self.height).each do |idx_y|
          image[idx_x, idx_y] = Color::grayscale_pixel self[idx_x, idx_y]
        end
      end
      image
    end

  end
end
