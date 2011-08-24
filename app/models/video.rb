class Video < ActiveRecord::Base
  include CommonVideo
  include Linktv::Platform::CommonThumbnail

  disable_deletes # Enforce use of destroy so callback are hit

  has_many :video_play_stats
  has_many :video_files, :dependent => :destroy
  has_many :video_segments, :order => 'start_time ASC', :dependent => :destroy
  has_many :topic_video_segments, :dependent => :destroy
  has_many :topics, :through => :topic_video_segments, :uniq => true do
    # Scope topics based on the video segment existing and being live
    def live
      Topic.live.topic_video_segments_video_id_eq(proxy_owner.id).
        topic_video_segments_video_segment_live.
        scoped(:select => 'topics.*, SUM(topic_video_segments.score) score', :group => 'topics.id')
    end
  end
  has_many :region_videos, :dependent => :destroy
  has_many :regions, :through => :region_videos
  has_many :resource_attrs, :as => :resource, :dependent => :destroy
  has_many :external_contents, :through => :video_segments
  has_many :playlist_items, :as => :playlistable_item
  has_many :playlists, :through => :playlist_items
  belongs_to :imported_video
  belongs_to :video_source

  has_and_belongs_to_many :restricted_countries, :class_name => 'Country',
    :join_table => :geo_restrictions

  has_permalink :name, :if => Proc.new{|v| v.published}

  validates_presence_of :name, :media_type
  validate :validate_associations
  def validate_associations
    self.topic_video_segments.each do |tvs|
      errors.add_to_base "Has invalid topic mapping ##{tvs.id}" unless tvs.video_segment.present?
      errors.add_to_base "Has invalid topic assocations ##{tvs.id}" unless tvs.topic.present?
    end
  end

  begin
    @@media_types = APP_CONFIG[:media_types].collect{|mt| [mt[:key].to_sym, mt[:display_name]]}
    cattr_reader :media_types
    symbolize :media_type, :in => Hash[@@media_types], :i18n => false
  end

  delegate :link, :license, :notes, :to => :imported_video

  accepts_nested_attributes_for :video_segments, :reject_if => proc {|attrs| attrs.all? {|k,v| v.blank?}}
  accepts_nested_attributes_for :resource_attrs, :reject_if => proc {|attrs| attrs['value'].blank?}
  accepts_nested_attributes_for :video_files, :reject_if => proc {|attrs| attrs['id'].blank? && attrs['url'].blank?}

  def before_validation
    self.media_type ||= :internal
    self.published_at ||= Time.now
  end

  begin
    named_scope :live, :conditions => {:deleted => false}
    def live?; !deleted end
  end

  alias_scope :with_available_video_files, lambda {
    Video.video_files_available.scoped(
      :group => "videos.id")
  }

  named_scope :include_thumbnail, :include => :thumbnail

  named_scope :default_scoring, {
    :select => 'videos.*, 1 score, (1 + videos.recommended) recommended_score',
    :group => 'videos.id'
  }

  # Find the videos related to ANY of the topics. Assume topics have already been
  # screened to be "live" as necessary.
  alias_scope :related_to_topics, lambda {|topic_ids|
    Video.topics_id_eq(topic_ids).scoped(
      :select => "videos.*, #{Topic.scaled_score} * SUM(topic_video_segments.score) score",
      :group => "videos.id"
    )
  }

  # Find the videos related to ALL of the topics. Assume topics have already been
  # screened to be "live" as necessary.
  alias_scope :related_to_all_topics, lambda {|topic_ids|
    topic_count = topic_ids.is_a?(Array) ? topic_ids.count : 1
    Video.topics_id_eq(topic_ids).scoped(
      :select =>
        "videos.*, " +
        "COUNT(DISTINCT topics.id) topic_count, " +
        "#{Topic.scaled_score} * SUM(topic_video_segments.score) score, " +
        "#{Topic.scaled_score} * SUM(topic_video_segments.score * (videos.recommended + 1)) recommended_score",
      :having =>
        ["topic_count = ?", topic_count],
      :group => 'videos.id'
    )
  }

  alias_scope :in_playlist, lambda {|user_id, playlist_permalink|
    Video.playlists_user_id_eq(user_id).playlists_permalink_eq(playlist_permalink)
  }

  # Ordering modes used in views
  named_scope :order_by, lambda {|arg|
    case arg
    when :relevance
      order = 'score DESC'
    when :newest
      order = 'published_at DESC'
    when :'a-z'
      order = 'name'
    else # Recommended
      order = 'recommended_score DESC'
    end
    {:order => order}
  }

  named_scope :with_video_play_stats, {
    :select => "videos.*, COUNT(video_play_stats.id) play_count",
    :joins => self.left_outer_joins(:video_play_stats),
    :group => 'videos.id'
  }

  begin
    def published_now?
      self.published && (self.published_at.nil? || Time.now.utc.to_i >= self.published_at.utc.to_i)
    end
    # Note: must use lambda for Time.now to be evaluted at execution time!
    named_scope :published_now, lambda {
      {
        :conditions => [
          "videos.published = 1 AND (videos.published_at IS NULL OR (UNIX_TIMESTAMP(?) - UNIX_TIMESTAMP(videos.published_at)) >= 0)",
          Time.now.utc.to_s(:db)]
      }
    }
  end

  # Find videos related to a set of video segments.
  alias_scope :related_to_video_segments, lambda {|video_segment_ids|
    Video.scoped(
      # TODO: score computation not DRY with video_segment.rb
      :select => "videos.*, #{VideoSegment.match_score} score",
      :group => 'videos.id'
    ).
    # Omit availability check and do it manually in this scope, since we're selecting form the Video table
    video_segments_related_to_video_segments(video_segment_ids)
  }

  # Find videos related to other videos.
  alias_scope :related_to_videos, lambda {|video_ids|
    Video.scoped(
      :select => "videos.*, #{VideoSegment.match_score} score",
      :group => 'videos.id'
    ).
    video_segments_related_to_videos(video_ids)
  }

  begin
    # Note: unrestricted scope not currently in use
    alias_scope :unrestricted, lambda {|country|
      raise ArgumentError if country.nil?
      if country.is_a? Country
      elsif country.is_a? Symbol
        raise ArgumentError unless country == :undefined
      elsif country.is_a? Integer
        country = Country.find_by_id country
        raise ArgumentError if country.nil?
      else
        raise ArgumentError
      end

      Video.
        scoped(:joins => left_outer_joins(:restricted_countries)).
        scoped(:conditions =>
          (country.present? && country != :undefined ) ?
            ["geo_restrictions.video_id IS NULL OR geo_restrictions.country_id = ?", country] :
            ["geo_restrictions.video_id IS NULL"])
    }

    def unrestricted? country
      # Note: These conditions should match the :unrestricted named scope
      return false unless published_now? && !deleted
      return true if restricted_countries.count == 0 # Unrestricted
      return false if country.nil? || country == :undefined # Checking for unrestricted videos, and this one is not

      country = country.id unless country.is_a? Integer
      return true if restricted_countries.map{|c| c.id}.include? country
      false
    end
  end

  begin
    alias_scope :available, lambda {
      Video.live.published_now.with_available_video_files
    }

    def available?
      live? && published_now? && video_files.available.count > 0
    end
  end

  begin
    alias_scope :featured, lambda {
      Video.in_playlist(nil, 'featured-videos')
    }

    def is_featured
      self.class.featured_videos_by_id[self.id].present?
    end
  end

  # Convenience method for polymorphic references
  def video
    self
  end

  def self.featured_videos_playlist
    @@featured_videos_playlist ||= Playlist.scoped_by_user_id(nil).scoped_by_permalink(:"featured-videos").first
  end

  def is_featured= value
    featured_videos = self.class.featured_videos_playlist
    if value == true || value.is_a?(String) && value.to_i == 1
      featured_videos.add self
    else
      featured_videos.remove self
    end
  end

  def after_create
    add_segment :start_time => 0, :active => true if video_segments.empty?
  end

  def imported_video_keywords
    imported_video.nil? ? nil : imported_video.media_keywords.strip.split(/\s*,\s*/)
  end

  # Dynamic status depends on video files
  def status
    return :deleted if deleted
    ready_count = 0
    video_files.live.each do |file|
      ready_count += 1 if file.status == :available
    end
    return :ready if ready_count == video_files.live.count && video_files.live.count > 0
    return :partially_ready if ready_count > 0
    return :not_ready
  end

  # published_at helper accessors generate the db field based on separate date and time
  attr_accessor :published_date, :published_time
  def published_date= value
    if published_at.present?
      self.published_at = published_at - published_at.midnight + Time.parse(value).midnight
    else
      self.published_at = Time.parse(value).midnight
    end
  end
  def published_time= value
    # TODO verify formats are parseable, i.e. HH:MM
    self.published_at = 0 if published_at.nil?
    time = Time.parse(value)
    self.published_at = published_at.midnight + (time - time.midnight).to_i
  end

  def has_thumbnail?
    self.thumbnail.present? && self.thumbnail.exists?
  end

  def has_thumbnail_url?
    imported_video.present? && imported_video.thumbnail_url.present?
  end

  # Download the image thumbnail and create an image resource
  def download_thumbnail
    return false if has_thumbnail? || !has_thumbnail_url?
    thumbnail_url = imported_video.thumbnail_url

    self.thumbnail = Image.create! :filename => File.basename(thumbnail_url),
        :source_url => imported_video.thumbnail_url unless self.thumbnail.present?
    return false unless thumbnail.download
    self.save!
  end

  def add_segment params
    video_segments.create params
  end

  def resource_attr_by_name name
    self.resource_attrs.each do |attr|
      return attr if attr.name == name
    end
    nil
  end

  def download_from_source user
    return false if video_files.empty?

    log user, "Processing video_file downloads"

    # Note: this call may update the log, run self.update afterwards
    video_files.live.each {|f| f.download_from_source user}
    self.reload

    download_thumbnail
    true
  end

  def destroy_non_static_external_contents
    return ExternalContent.destroy_all [
      "video_id = ? AND semantic_api_id IS NOT NULL AND deleted = 0 AND sticky = 0", self.id]
  end

  # Fetch and save all content types for the video segments
  # TODO: ensure only one pending job
  def update_all_external_contents_later
    # Requires delayed_job
    return unless self.respond_to? :send_later
    send_later :update_all_external_contents
  end

  # Fetch and save all content types for the video segments
  def update_all_external_contents
    self.video_segments.live.each {|s| s.update_all_external_contents}
  end

  # Check external content age for all segments. If a segment id is supplied,
  # and args[:block] is true,
  # the method will block while contents are fetched from API's.
  # Otherwise, the API hits are scheduled in the background.
  def check_external_contents video_segment_id = nil, args = {}
    ret = nil
    self.video_segments.live.ordered.each do |segment|
      if video_segment_id.present? && segment.id == video_segment_id
        ret = segment.check_external_contents({:block => (args[:block] || false)})
      else
        segment.check_external_contents_later
      end
    end
    ret
  end

  def register_play args
    VideoPlayStat.create!(
      :video_id => self.id,
      :video_segment_id => args[:video_segment_id] || nil,
      :ip => args[:ip] || nil,
      :http_user_agent => args[:http_user_agent] || nil,
      :http_referer => args[:http_referer] || nil,
      :user_id => args[:user_id] || nil
    )
  end

  def self.featured_videos_by_id
    unless defined? @@featured_videos
      @@featured_videos = {}
      items = PlaylistItem.playlist_user_id_eq(nil).
        playlist_permalink_eq('featured-videos')
      videos_by_id = self.find_all_by_id(items.collect{|i| i.playlistable_item_id}).
        inject({}) {|h, video| h.merge(video.id => video)}
      items.each do |item|
        @@featured_videos[item.playlistable_item_id] = videos_by_id[item.playlistable_item_id]
      end
    end
    @@featured_videos
  end

  def topics_for_admin
    self.topics.live.include_entity_identifiers.order('topics.name')
  end

  def play_count
    video_play_stats.count
  end

  def get_video_files request_country
    if self.unrestricted? request_country
      return self.video_files.available.media_type_eq(self.media_type).ordered
    else
      return []
    end
  end

  # sunspot (solr) fulltext searching
  # http://wiki.github.com/outoftime/sunspot/setting-up-classes-for-search-and-indexing

  searchable do
    text :name, :boost => 2.0
    text :description
    text :segment_names do
      video_segments.map { |segment| segment.name }
    end
    text :segment_transcripts do
      video_segments.map { |segment| segment.transcript_text }
    end
    boolean :available do
      self.available?
    end
    string :name
    time :published_at
    integer :play_count
  end

  def expected_permalink
    # Before video is published we don't set the permalink, but might want to know what it might be
    # This ignores naming conflicts
    PermalinkFu::escape name
  end

end




# == Schema Information
#
# Table name: videos
#
#  id                  :integer(4)      not null, primary key
#  imported_video_id   :integer(4)
#  name                :string(255)
#  description         :text
#  permalink           :string(255)
#  duration            :integer(4)
#  media_type          :string(40)
#  transcript_text     :text
#  source_published_at :datetime
#  source_name         :string(255)
#  source_link         :string(255)
#  video_source_id     :integer(4)
#  download_enabled    :boolean(1)      default(FALSE), not null
#  published           :boolean(1)      default(FALSE), not null
#  published_at        :datetime
#  log_text            :text
#  recommended         :boolean(1)      default(FALSE), not null
#  deleted             :boolean(1)      default(FALSE), not null
#  embeddable          :boolean(1)
#  created_at          :datetime
#  updated_at          :datetime
#

