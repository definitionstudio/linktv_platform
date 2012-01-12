class ImportedVideo < ActiveRecord::Base
  
  include CommonVideo

  belongs_to :status_by_user, :class_name => 'User'

  symbolize :status, :in => [:new, :accepted, :rejected]

  validates_presence_of :name, :link, :guid, :xml
  validates_uniqueness_of :guid, :scope => :video_source_id

  def parse_xml
    @attr = Mrss::Item.parse(self.xml) unless @attr
    @attr
  end

  def published_status
    false
  end

  def is_imported_video?
    true
  end

  def imported_video
    self
  end

  def name
    parse_xml
    @attr.title
  end

  def link
    parse_xml
    @attr.link
  end

  def media_url
    parse_xml
    if @attr.media_group
      @attr.media_group.media_contents.max{|a, b| a.media_content_bitrate <=> b.media_content_bitrate}.media_content_url
    elsif @attr.media_contents
      @attr.media_contents.max{|a, b| a.media_content_bitrate <=> b.media_content_bitrate}.media_content_url
    else
      @attr.enclosure_url
    end
  end

  def video_files
    parse_xml
    if @attr.media_group || @attr.media_contents
      # Multiple video files
      contents = @attr.media_group ? @attr.media_group.media_contents : @attr.media_contents
      contents.sort!{|a, b|
        a.media_content_bitrate.to_i <=> b.media_content_bitrate.to_i     # TODO: bitrate value not reliable
      }
      contents.collect {|content|
        VideoFile.new({
          :status => :provisioned,
          :url => content.media_content_url,
          :file_size => content.media_content_filesize,
          :mime_type => content.media_content_type,
          :bitrate => content.media_content_bitrate,
          :media_type => :internal,
          :active => true
        })
      }
    else
      # Only one video file (enclosure)
      [VideoFile.new({
        :status => :provisioned,
        :url => @attr.enclosure_url,
        :file_size => @attr.enclosure_length,
        :mime_type => @attr.enclosure_type,
        :media_type => :internal,
        :active => true
      })]
    end
  end

  def thumbnail_url
    parse_xml
    if @attr.media_group
      @attr.media_group.media_thumbnail_url
    else
      @attr.media_thumbnail_url
    end
  end

  def description
    parse_xml
    @attr.description
  end

  def license
    parse_xml
    @attr.media_license || @attr.creativecommons_license || 'Unknown'
  end

  def source_published_at
    parse_xml
    @attr.published_at
  end

  def media_keywords
    parse_xml
    if @attr.media_group
      str = @attr.media_group.media_keywords
    else
      str = @attr.media_keywords
    end
    str.nil? ? '' : str
  end

  def media_duration
    parse_xml
    if @attr.media_group
      @attr.media_group.media_contents[0].media_content_duration rescue nil
    elsif @attr.media_contents
      @attr.media_contents[0].media_content_duration
    else
      nil
    end
  end

  def media_scenes
    parse_xml
    if @attr.media_group
      scenes = @attr.media_group.media_scenes.media_scene rescue nil
    else
      scenes = @attr.media_scenes.media_scene rescue nil
    end
    if !scenes.nil?
      scenes.sort{|a, b|
        a.sceneStartTime.to_i <=> b.sceneStartTime.to_i
      }
      scenes.collect {|scene|
        VideoSegment.new({
          :start_time => scene.sceneStartTime,
          :name => scene.sceneTitle,
          :transcript_text => scene.sceneDescription,
          :active => true
        })
      }
    else
      nil
    end
  end

  def transcript_text
    # Note: filter to ensure all newlines are \r\n
    parse_xml
    if @attr.media_group
      @attr.media_group.media_text.gsub(/\r(\n)?|\n(\r)?/, "\r\n") rescue nil
    else
      @attr.media_text.gsub(/\r(\n)?|\n(\r)?/, "\r\n") rescue nil
    end
  end

  def reject args = {}
    self.status = :rejected
    self.status_at = Time.now.to_i
    self.status_by_user = args[:user]
    self.notes = args[:notes] || nil
    log args[:user], "rejected"
    return save!
  end

  def accept args = {}
    self.status = :accepted
    self.status_at = Time.now.to_i
    self.status_by_user = args[:user]
    self.notes = args[:notes] || nil
    log args[:user], "accepted"
    if !save!
      return false
    end

    # Create a new video record
    # TODO: possible race condition where two videos could be created from a single imported video
    video = self.create_video
    video.log args[:user], "accepted from ImportedVideo##{self.id}"
    video.download_from_source args[:user]
    video
  end

  def create_video
    video = Video.new(
      :imported_video_id => self.id,
      :name => self.name,
      :description => self.description,
      :transcript_text => self.transcript_text,
      :duration => self.media_duration.to_i,
      :media_type => :internal,
      :source_published_at => self.source_published_at,
      :source_name => self.video_source.name,
      :source_link => self.link,
      :published_at => self.source_published_at || Time.now.to_i,
      :video_source_id => self.video_source_id
    )
    self.video_files.each {|f| video.video_files << f} rescue nil
    self.media_scenes.each {|s| video.video_segments << s} rescue nil
    video.save!
    video
  end

  protected

  def self.create_from_feed_if_new video_source, item
    guid = item.xpath('guid').text
    return false if guid.blank? || exists?(:video_source_id => video_source.id, :guid => guid)

    # Extract a minimal set of attributes. Full XML will be decoded later if/when the video is accepted.
    create!(
      :guid => guid,
      :video_source_id => video_source.id || nil,
      :source_published_at => item.xpath('pubDate').text,
      :name => item.xpath('title').text,
      :link => item.xpath('link').text,
      :xml => item.to_xml,
      :status => :new
    )
  end
end




# == Schema Information
#
# Table name: imported_videos
#
#  id                  :integer(4)      not null, primary key
#  video_source_id     :integer(4)
#  name                :string(1024)
#  link                :string(1024)
#  guid                :string(1024)
#  xml                 :text
#  log_text            :text
#  status              :string(255)
#  status_by_user_id   :integer(4)
#  status_at           :datetime
#  source_published_at :datetime
#  notes               :text
#  created_at          :datetime
#  updated_at          :datetime
#

