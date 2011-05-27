module Linktv::Platform::CommonThumbnail

  class << self

    def included base
      base.module_eval do
        has_one :thumbnail, :as => :has_image, :class_name => 'Image', :dependent => :destroy
        accepts_nested_attributes_for :thumbnail, :reject_if => proc {|attrs| attrs['id'].blank?}, :allow_destroy => true

        attr_accessor :tmp_thumbnail_attribution
        after_save :process_thumbnail_attribution
      end
    end

  end

  def thumbnail_id
    return nil if self.thumbnail.nil?
    self.thumbnail.id
  end

  def thumbnail_id= value
    return if value.blank?
    self.thumbnail = Image.find(value) || nil
  end

  def thumbnail_attribution
    return nil if self.thumbnail.nil?
    self.thumbnail.attribution
  end

  def thumbnail_attribution= value
    if self.thumbnail.nil?
      self.tmp_thumbnail_attribution = value
      return nil
    end
    self.thumbnail.attribution = value
    self.thumbnail.save!
  end

  protected

  def process_thumbnail_attribution
    return if self.tmp_thumbnail_attribution.nil?
    self.thumbnail_attribution = self.tmp_thumbnail_attribution
  end

end