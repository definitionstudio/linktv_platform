class VideoSource < ActiveRecord::Base

  has_many :imported_videos
  has_many :videos

  named_scope :live, :conditions => {:active => true, :deleted => false}
  named_scope :with_feed, :conditions => 'feed_url IS NOT NULL'

  include Exceptions

  def new_imported_video_count
    self.imported_videos.status_new.count
  end

  def video_count
    self.videos.count
  end

  def active?
    return self.active && !self.deleted
  end

  def has_feed?
    return self.feed_url.present?
  end

  def read_feed
    require 'uri'
    require 'net/https'
    uri = URI.parse self.feed_url
    body = nil
    begin
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = uri.scheme == 'https'
      http.start do |http|
        req_path = (uri.query.blank?) ? uri.path : uri.path + '?' + uri.query
        req = Net::HTTP::Get.new req_path
        if !self.auth_username.blank? && !self.auth_password.blank?
          req.basic_auth(self.auth_username, self.auth_password)
        end
        response = http.request req
        body = response.body
      end
    rescue SocketError => error
      # TODO: error handling, return message to caller
      puts 'socket error'
    rescue => error
      # TODO: error handling, return message to caller
      puts 'other error'
      puts error.inspect
    end

    body
  end

  def update_feed
    if (self.feed_url.blank?)
      raise UnsupportedOperation
    end

    body = read_feed
    return nil if body.nil? or body.empty?

    new_items = 0
    doc = Nokogiri::XML body
    items = doc.xpath('//channel/item')
    items.each do |item|
      imported_video = ImportedVideo.create_from_feed_if_new self, item
      if imported_video
        new_items += 1
        imported_video.accept :comments => 'Auto-accepted' if self.auto_accept_videos
      end
    end
    return new_items, items.size
  end

  # cron task
  def self.update_feeds
    log = Time.now.utc.to_s + " VideoSource.update_feeds begin\n"
    VideoSource.live.with_feed.each do |source|
      log << Time.now.utc.to_s << " Update VideoSource ##{source.id} \"#{source.name}\" begin\n"
      new_items, size = source.update_feed
      log << Time.now.utc.to_s << " Imported #{new_items} new items from a total of #{size}\n"
      log << Time.now.utc.to_s << " Update VideoSource ##{source.id} \"#{source.name}\" end\n"
    end
    log << Time.now.utc.to_s << " VideoSource.update_feeds end\n"
  end

end




# == Schema Information
#
# Table name: video_sources
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  description        :text
#  feed_url           :string(1024)
#  auth_username      :string(255)
#  auth_password      :string(255)
#  auto_accept_videos :boolean(1)      default(FALSE), not null
#  active             :boolean(1)      default(FALSE), not null
#  deleted            :boolean(1)      default(FALSE), not null
#  created_at         :datetime
#  updated_at         :datetime
#

