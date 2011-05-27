class Image < ActiveRecord::Base
  
  belongs_to :has_image, :polymorphic => true
  include ThumbnailGenerator

  def base_dir
    "base-#{((id / 1000).to_i * 1000).to_s}"
  end

  def path_structure
    File.join base_dir, id.to_s
  end

  def cache_path
    File.join IMAGE_CACHE_PATH, self.path_structure
  end

  def cache_dir
    File.join IMAGE_CACHE_ROOT, self.path_structure
  end

  def dir
    raise "id cannot be nil" if id.nil?
    File.join PRIVATE_IMAGES_ROOT, self.path_structure
  end

  def pathname
    File.join dir, filename
  end

  def exists?
    File.exists? self.pathname
  end

  def mkdir
    FileUtils.mkdir_p dir
  end

  def write data
    mkdir
    File.open(pathname, "w") {|f| f.write data}
  end

  def download
    return true if File.exists?(self.pathname)
    return false unless source_url.present?
    return false if !pathname.nil? && File.exists?(self.pathname)

    require 'open-uri'
    begin
      read_file = open source_url
    rescue => error
      # Catch 404, etc...
      logger.info "Image#download error=[#{error.inspect}] url=[#{source_url}]"
      return false
    end

    begin
      mkdir
      write_file = File.new self.pathname, "w"
      write_file.write read_file.read
    rescue => exc
      # Silently fail if download is not successful
      # Perhaps the disk was full, or something is wrong with permissions
      return false
    end
    true
  end

  def thumbnail args = {}
    # Remove trailing query params that rails might add to the image URL
    filename = "thumbnail"
    filename += ".#{args[:options]}" unless args[:options].blank?
    filename += ".#{args[:format]}"

    args[:cache_pathname] = File.join cache_dir, filename
    self.class.thumbnail pathname, args
  end

  # TODO: optimizations
  # 1. Remove image records that are not associated to another record
  # 2. Remove image files from filesystem that do not have image records
  # Note that this may disrupt the running server, so run when system is offline
  def self.cleanup
    # First delete the orphaned records, i.e. Image instance without owners
    self.orphaned.each {|i| i.destroy}

    # Remove any file system orphans
    Dir["#{PRIVATE_IMAGES_ROOT}/*", "#{IMAGE_CACHE_ROOT}/*"].each do |base_dir|
      Dir["#{base_dir}/*"].each do |dir|
        image_id = (File.basename dir).to_i
        next if Image.find_by_id image_id
        return dir
        FileUtils.rm_rf dir
      end
    end
    
    true
  end

  def self.orphaned
    # has_image is polymorphic and cannot be joined
    # considering only old (24 hours) entries in case the image is provisional
    #  (not yet linked) and to avoid need for db locking
    Image.find(:all, :conditions => ['created_at < ?', 1.day.ago]).reject{|i| i.has_image_id.present? && i.has_image.present?}
  end

  # Note: avoid calling Image.delete which will not delete the media files
  def after_destroy
    delete_media
  end

  def delete_media
    FileUtils.rm_rf self.dir if File.exist? self.dir
    FileUtils.rm_rf self.cache_dir if File.exist? self.cache_dir
  end

  def self.image_not_available_path
    File.join(RAILS_ROOT, 'public', APP_CONFIG[:thumbnails][:not_available_path])
  end

end


# == Schema Information
#
# Table name: images
#
#  id             :integer(4)      not null, primary key
#  filename       :string(255)
#  has_image_type :string(255)
#  has_image_id   :integer(4)
#  source_url     :string(1024)
#  created_at     :datetime
#  updated_at     :datetime
#

