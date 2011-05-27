require 'aws/s3'
include AWS::S3

class VideoFile < ActiveRecord::Base
  
  belongs_to :video

  def to_label
    "Video File"
  end

  symbolize :status, :in => [:provisioned, :download_requested, :downloading,
    :downloaded, :upload_requested, :uploading, :available, :obsolete, :error]

  validates_presence_of :media_type, :status

  named_scope :available, :conditions => {:active => true, :deleted => false, :status => :available}
  def available
    active && !deleted && status == :available
  end

  begin
    def live?
      active && !deleted
    end
    # Note: don't add status check to :live, it disables video downloading - RD
    named_scope :live, :conditions => {:active => true, :deleted => false}
  end

  named_scope :ordered, :order => 'file_size ASC'

  def before_validation
    if is_youtube
      self.media_type = :youtube
      self.status = :available
      self.url = "http://www.youtube.com/v/" + youtube_id
    else
      self[:status] = :provisioned if @url_changed && media_type.to_sym == :internal || nil
    end
  end

  def authorized_for_download?
    return true if media_type.to_sym == :internal
    false
  end

  def is_youtube
    url =~ /^http:\/\/((?:www\.)?youtube\.com|youtu\.be)/i
  end

  def youtube_id
    is_youtube ? parse_youtube_id(url) : nil
  end

  def parse_youtube_id uri
    matches = uri.match(/^http:\/\/(?:www\.)?youtube\.com\/v\/([^&\/]*)/i)
    matches = uri.match(/^http:\/\/(?:www\.)?youtube\.com\/watch\?(?:.+&)*v=([^&]*)/i) if matches.nil?
    matches = uri.match(/^http:\/\/youtu\.be\/([^&\/]*)/i) if matches.nil?
    return matches[1] rescue nil
  end

  # Reference key for UI use
  attr_accessor :key

  # Virtual attribute is only used to differentiate placeholder instances in admin
  attr_accessor :is_cdn

  def media_type_display_name
    return @media_type_display_name if @media_type_display_name.present?

    media_types = APP_CONFIG[:media_types]
    instance_type = media_types.select{|t| t[:key] == self.media_type.to_s}.
      first[:media_instance_types].select{|t| t == self.media_instance_type}.first
    
    @media_type_display_name = [
      # Imported videos will not yet be mapped to a media_instance_type
      (!instance_type.blank? ? instance_type : self.url),
      (!bitrate.blank? ? " (#{bitrate}Kbps)" : ''),
      (is_cdn ? ' CDN' : nil)].reject{|x| x.nil?}.join(' ')
  end

  def url= value
    return if self.url == value
    @url_changed = true
    super value
  end

  # Downloads the video from the source feed directly to Amazon S3
  # Requires delayed_job gem
  def download_from_source user
    self.class.download_from_source user, self
  end

  def maybe_download_from_source user
    return false unless self.status == :provisioned
    download_from_source user
  end

  # Downloads the video from the source feed directly to Amazon S3
  # Requires delayed_job gem
  def self.download_from_source user, video_file
    return true if video_file.media_type.to_sym != :internal
    video_file.update_attribute :status, :download_requested

    # schedule download in the background
    video_file.video.log user, "download requested, video_file##{video_file.id}"

    if !APP_CONFIG[:video_files][:cdn_enable] || DEVELOPMENT_MODE
      video_file.do_download_from_source user
    else
      #return false unless video_file.respond_to? :send_later
      video_file.send_later(:do_download_from_source, user)
    end
    true
  end

  def do_download_from_source user
    return false unless self.live?
    return false unless self.status == :download_requested

    self.video.log user, "download initiated, video_file##{self.id}"
    self.update_attribute :status, :downloading

    begin

      # Note: Use video.expected_permalink rather than video.permalink for name since permalink
      # might not be set (if video is not yet published)
      target_filename = "#{self.video.expected_permalink}-#{self.id.to_s}#{File.extname(self.url.to_s)}"

      if APP_CONFIG[:video_files][:cdn_enable]
        # transfer to S3
        AWS::S3::Base.establish_connection!(:access_key_id => APP_CONFIG[:video_files][:s3_access_key],:secret_access_key => APP_CONFIG[:video_files][:s3_secret_key])
        success = S3Object.store(target_filename, open(self.url.to_s), APP_CONFIG[:video_files][:s3_bucket],
          :access => :public_read)
        self.video.log user, "upload to CDN completed, video_file##{self.id}" if success
        
        # get uploaded file size
        uploaded = S3Object.find target_filename, APP_CONFIG[:video_files][:s3_bucket]
        content_length = uploaded.about['content-length']

        unless content_length.to_i > 0
          success = false
          msg = "Content length not > 0"
        end

      else
        success = true
        self.video.log user, "simulated upload to CDN completed, video_file##{self.id}"
        content_length = 0
      end

      if success
        # update attributes
        self.update_attributes!(
          :cdn_path => target_filename,
          :file_size => content_length,
          :status => :available)
      else
        self.video.log user, "upload to CDN failed, video_file##{self.id} " + (msg || '')
        self.update_attribute :status, :error
      end

    rescue Exception => exc
      logger.error exc.message
      self.video.log user, "upload to CDN failed (exception), video_file##{self.id} " + (exc.message || '')
      self.update_attribute :status, :error

      # raise error for DelayedJob error logging
      raise exc
    end

  end

  def identifier
    stream_host = APP_CONFIG[:video_host][:stream_host] || nil
    if media_type.to_sym == :internal
      return stream_host.present? ? "mp4:#{cdn_path}" : url
    elsif media_type.to_sym == :youtube
      return url
    end
    return nil
  end

  def download_url
    return url if cdn_path.nil? || APP_CONFIG[:video_host][:download_host].blank?
    "#{APP_CONFIG[:video_host][:download_host]}/#{cdn_path}"
  end

  def human_format
    mime_type.present? ? mime_type.sub(/video\//, '').upcase : 'Unknown'
  end

  def filename
    url.sub(/.*\//, '')
  end

  def media_instance_type= value
    @media_instance_type = value
  end
  def media_instance_type
    # Youtube supports only a single media_instance_type
    # Otherwise video must manually set it to non-nil
    return @media_instance_type if @media_instance_type.present?
    if media_type == :youtube
      @media_instance_type = 'Youtube'
    end
    @media_instance_type
  end

end


# == Schema Information
#
# Table name: video_files
#
#  id         :integer(4)      not null, primary key
#  video_id   :integer(4)
#  url        :string(1024)
#  cdn_path   :string(1024)
#  media_type :string(40)
#  file_size  :integer(4)
#  mime_type  :string(255)
#  bitrate    :integer(4)
#  status     :string(255)
#  active     :boolean(1)      default(FALSE), not null
#  deleted    :boolean(1)      default(FALSE), not null
#  created_at :datetime
#  updated_at :datetime
#

