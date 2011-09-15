class VideoSegment < ActiveRecord::Base

  include Linktv::Platform::CommonThumbnail

  disable_deletes # Enforce use of destroy so callback are hit

  belongs_to :video
  has_many :video_play_stats
  has_many :topic_video_segments,
    :dependent => :destroy
  has_many :topics, :through => :topic_video_segments

  has_many :external_contents do
    # Index and return ExternalContent by content type id
    def by_content_type
      result = {}
      self.find_all.each do |content|
        (result[content.content_type_id] ||= []) << content
      end
      result
    end

    # Index and return ExternalContent by content type name
    def by_content_type_name
      result = {}
      self.find(:all, :include => :content_type).each do |content|
        (result[content.content_type.name] ||= []) << content
      end
      result
    end
  end

  accepts_nested_attributes_for :topic_video_segments, :allow_destroy => 1,
    :reject_if => proc {|attrs| attrs.all? {|k,v| v.blank?}}
  accepts_nested_attributes_for :external_contents, :allow_destroy => 1,
    :reject_if => proc {|attrs| attrs.all? {|k,v| v.blank?}}

  # Allow storage of set of relevant topics within a search scope
  attr_accessor :relevant_topics
  attr_accessor :view_data

  named_scope :ordered, :order => 'start_time ASC'

  named_scope :live,
    :joins => "INNER JOIN videos ON video_segments.video_id = videos.id",
    :conditions=> ['videos.deleted = ? AND video_segments.active = ? AND video_segments.deleted = ?', 0, 1, 0]

  def live?; active && !deleted end

  named_scope :include_thumbnail, :include => :thumbnail

  delegate :available?, :to => :video

  # Score matches
  # - Use the lower of the two TopicVideoSegment#score values
  # - Sum them for the group (Video or VideoSegment)
  # - Divide by the number of topic matches, to get an average score per topic
  # - Multiply again by the number of distinct topics (only functions for Video lookups)
  #   to weight more topic matches higher
  def self.match_score
    return <<-EOS
      #{Topic.scaled_score} *
        SUM(IF(topic_video_segments.score < tvs2.score, topic_video_segments.score, tvs2.score))
    EOS
  end

  alias_scope :related_to_topics, lambda {|topic_ids|
    VideoSegment.topics_id_eq(topic_ids).
      scoped(:select => "video_segments.*, topic_video_segments.score score")
  }

  # Find segments related to another set of segments.
  # This is done by joining related topics, and scoring the match as the sum of
  # the scores for all the matches for a set of segments.
  # Caller should include videos and check for availability as necessary
  # i.e. VideoSegment.related_to_video_segments([1,2]).join_video.available(226)
  named_scope :related_to_video_segments, lambda {|video_segment_ids|
    {
      :select => "video_segments.*, #{self.match_score} score",
      :joins => VideoSegment.inner_joins(:topics) + [
        "INNER JOIN topic_video_segments tvs2 ON tvs2.topic_id = topic_video_segments.topic_id",
        "INNER JOIN video_segments video_segments2 ON video_segments2.id = tvs2.video_segment_id"],
      :conditions => [
        "topic_video_segments.score >= 0 AND tvs2.score >= 0 AND " +
        "video_segments.id NOT IN (?) AND video_segments2.id IN (?)",
        video_segment_ids, video_segment_ids],
      :order => 'score DESC',
      :group => 'video_segments.id'
    }
  }

  named_scope :related_to_videos, lambda {|video_ids|
    {
      :select => "video_segments.*, #{self.match_score} score",
      :joins => VideoSegment.inner_joins(:topics) + [
        "INNER JOIN topic_video_segments tvs2 ON tvs2.topic_id = topic_video_segments.topic_id",
        "INNER JOIN videos videos2 ON videos2.id = tvs2.video_id"],
      :conditions => [
        "topic_video_segments.score >= 0 AND tvs2.score >= 0 AND " +
        "video_segments.video_id NOT IN (?) AND videos2.id IN (?)",
        video_ids, video_ids],
      :order => 'score DESC',
      :group => 'video_segments.id'
    }
  }

  # Find the video segments related to ANY of the topics. Assume topics have already been
  # screened to be "live" as necessary.
  # TODO DRY this up with corresponding scope in Video
  alias_scope :related_to_topics, lambda {|topic_ids|
    VideoSegment.topics_id_eq(topic_ids).scoped(
      :select => "video_segments.*, #{Topic.scaled_score} * SUM(topic_video_segments.score) score",
      :group => "video_segments.id"
    )
  }

  # Find the video segments related to ALL of the topics. Assume topics have already been
  # screened to be "live" as necessary.
  # TODO DRY this up with corresponding scope in Video
  alias_scope :related_to_all_topics, lambda {|topic_ids|
    topic_count = topic_ids.is_a?(Array) ? topic_ids.count : 1
    VideoSegment.topics_id_eq(topic_ids).scoped(
      :select =>
        "video_segments.*, " +
        "COUNT(DISTINCT topics.id) topic_count, " +
        "#{Topic.scaled_score} * SUM(topic_video_segments.score) score, " +
        "#{Topic.scaled_score} * SUM(topic_video_segments.score * (videos.recommended + 1)) recommended_score",
      :having =>
        ["topic_count = ?", topic_count],
      :group => 'video_segments.id'
    )
  }


  def start_time= value
    match = value.match(/^((\d*):)??((\d*):)?(\d*)$/) if value.is_a?(String)
    value = $2.to_i * 3600 + $4.to_i * 60 + $5.to_i if match
    write_attribute :start_time, value
  end

  def api_data
    self.transcript_text
  end

  # Fetch external content for a given content_type, a transcript and topics.
  # The video segment may not exist, or may be unsaved.
  # To be called by the admin interface when reloading individual content types.
  def self.query_external_contents title, transcript, topics_data, args = {}
    # Get the static contents, which will be retained, if the segment already exists
    contents_by_identifier = {}
    if args[:id].present?
      contents = ExternalContent.active.static.with_weighted_score.ordered_for_admin.scoped_by_video_segment_id args[:id]
      contents = contents.scoped_by_content_type_id args[:content_type_id] if args[:content_type_id].present?
      contents.each do |c|
        cid = c.identifier.empty? ? c.url : c.identifier
        contents_by_identifier[cid] = c
      end
    end

    if transcript.nil? || transcript.strip.empty?
      contents = []
    else
      contents_by_id = ExternalContent.query title, transcript, topics_data,
        :content_type_id => args[:content_type_id] || nil,
        :omit_identifiers => args[:omit_identifiers] || nil

      contents_by_id.each do |content_type_id, contents|
        contents.each do |content|
          next if contents_by_identifier[content.identifier]
          next if content.deleted
          contents_by_identifier[content.identifier] = content
        end
      end

      # sort order defined in ExternalContent model ('<=>')
      contents = contents_by_identifier.values.sort

      ExternalContent.filter_collection contents, topics_data
    end
    contents
  end

  def live_topics_data
    data = []
    collection = topic_video_segments.live.scoped(:include => :topic)

    # include entity identifiers in front-end query (needed for SocialActions API query)
    collection.each do |tvs|
      topic = {'name' => tvs.topic.name, 'score' => tvs.score, 'id' => tvs.topic.id, 'entity_identifiers' => {}}
      tvs.topic.entity_identifiers.each {|eid| topic['entity_identifiers'][eid.entity_db_id] = eid.identifier}
      data << topic
    end

    data
  end

  # Update external content based on front-end request if necessary.
  #
  # if unexpired content exists (i.e. 48 hours)
  #   if content is older than refresh interval (i.e. 15 minutes)
  #     schedule background job to refresh content
  # else
  #   fetch new data immediately for the segment (will delay request)
  #   schedule background job to refresh other segments
  # show existing content
  #
  # returns true if existing content is current
  #
  def check_external_contents args = {}
    mr_contents = self.external_contents.dynamic.most_recent
    mr_content = mr_contents && !mr_contents.empty? ? mr_contents[0] : nil
    lifetime = APP_CONFIG[:apis][:defaults][:external_content][:lifetime]
    age = mr_content ? Time.now.to_i - mr_content.created_at.to_i : lifetime + 1
    if mr_content && age < lifetime
      # Content exists, is ok to display, but may be due for a background update
      if age > APP_CONFIG[:apis][:defaults][:external_content][:refresh]
        self.update_all_external_contents_later
      end
      return true
    else
      if args[:block] || nil
        self.update_all_external_contents
      else
        self.update_all_external_contents_later
      end
      return false
    end
  end

  def check_external_contents_later
    return unless self.respond_to? :send_later
    return if self.external_update_pending
    send_later :check_external_contents
    self.update_attribute :external_update_pending, true
  end

  # Fetch and save all content types for the video segments
  # TODO: handle possible deadlock where external_update_pending is set, but fails to clear
  def update_all_external_contents_later
    return unless self.respond_to? :send_later
    return if self.external_update_pending
    send_later :update_all_external_contents
    self.update_attribute :external_update_pending, true
  end

  # Fetch and save all content types for the video segment
  def update_all_external_contents
    return [] if api_data.blank?

    self.update_attribute :external_update_pending, true unless self.external_update_pending

    contents = self.class.query_external_contents self.name, self.transcript_text, self.live_topics_data, :id => self.id

    unless contents.empty?
      # Delete any existing dynamic content
      ExternalContent.dynamic.destroy_all ["video_segment_id = ?", self.id]
      # Add back in the new dynamic content. Static content is already linked.
      contents.each {|c| self.external_contents << c if c.dynamic}
    end

    self.update_attribute :external_update_pending, false

    contents
  end

  def formatted_duration
    format_time(self.end_offset - self.start_offset)
  end

  def associate_topic topic
    self.topic_video_segments << TopicVideoSegment.create!(:topic => topic)
  end

  # For active scaffold
  def label
    "#{self.video.name} - #{self.name}"
  end

  def load_contents_data
    self.view_data ||= {}

    # Internal related videos
    self.view_data[:related_internal_videos] = Video.
      scoped(:conditions => ["videos.id != ?", self.video_id]).
      available.
      related_to_video_segments(self.id).
      include_thumbnail

    self.view_data[:related_internal_video_segments] = VideoSegment.
      scoped(:conditions => ["video_segments.video_id != ?", self.video_id]).
      scoped(:include => :video, :joins => :video).video_available.
      related_to_video_segments(self.id).
      include_thumbnail

    # Note: This does not set a scope but loads the collection.
    # Necessary since we'll be filtering the results
    self.view_data[:contents_by_type] =
      self.external_contents.live.
        with_weighted_score.include_content_sources.include_thumbnail.
        ordered.by_content_type

    live_topics_data = self.live_topics_data

    # Filter out by low score, duplicates, etc.
    self.view_data[:contents_by_type].each do |key, contents|
      ExternalContent.filter_collection contents, live_topics_data
      # For the front end, we don't display filtered items at all.
      contents.reject!{|c| c.filtered?}
    end
  end

  # sunspot (solr) fulltext searching
  # http://wiki.github.com/outoftime/sunspot/setting-up-classes-for-search-and-indexing

  searchable do
    text :name, :default_boost => 2
    text :transcript_text
    integer :video_id, :references => Video
  end

end



# == Schema Information
#
# Table name: video_segments
#
#  id                      :integer(4)      not null, primary key
#  temp_tag                :integer(4)
#  name                    :string(255)
#  video_id                :integer(4)
#  start_time              :integer(4)
#  transcript_text         :text
#  active                  :boolean(1)      default(FALSE), not null
#  deleted                 :boolean(1)      default(FALSE), not null
#  external_update_pending :boolean(1)      default(FALSE), not null
#  created_at              :datetime
#  updated_at              :datetime
#

