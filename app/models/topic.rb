class Topic < ActiveRecord::Base
  
  has_many :topic_video_segments, :dependent => :destroy
  has_many :video_segments, :through => :topic_video_segments
  has_many :videos, :through => :topic_video_segments
  has_many :entity_identifiers, :order => 'entity_db_id'
  has_many :entity_dbs, :through => :entity_identifiers
  has_many :playlist_items, :as => :playlistable_item
  has_many :playlists, :through => :playlist_items

  accepts_nested_attributes_for :entity_identifiers,
    :reject_if => proc {|attrs| attrs['identifier'].blank?},
    :allow_destroy => true

  has_permalink :name

  validates_presence_of :name
  validates_uniqueness_of :guid

  named_scope :ordered, :order => 'sort_name'

  begin
    named_scope :live, :conditions => {:active => true, :deleted => false}
    def live?; active && !deleted end
  end

  def self.scaled_score
    "COUNT(DISTINCT topics.id) / COUNT(topics.id)"
  end

  named_scope :order_by, lambda {|arg|
    case arg
    when :newest
      order = 'created_at DESC'
    when :popular
      order = 'video_count DESC'
    else # A-Z
      order = 'topics.sort_name' # default
    end
    {:order => order}
  }

  named_scope :include_entity_identifiers, :include => [
    {:entity_identifiers => [:entity_db]}
  ]

  alias_scope :in_playlist, lambda {|user_id, playlist_permalink|
    Topic.playlists_user_id_eq(user_id).playlists_permalink_eq(playlist_permalink)
  }

  # Use with :videos_available
  named_scope :with_video_count, {
    :select => "topics.*, COUNT(DISTINCT videos.id) video_count",
    :group => "topics.id"
  }

  alias_scope :with_videos, lambda {
    Topic.with_video_count.scoped(:conditions => "videos.id IS NOT NULL")
  }

  # Use with :videos_available
  named_scope :related_to_videos, lambda {|video_ids|
    {
      :select => "topics.*, SUM(topic_video_segments.score) score, COUNT(DISTINCT videos.id) video_count",
      :conditions => ["videos.id IN (?)", video_ids],
      :group => "topics.id"
    }
  }

  # available on front-end
  named_scope :public, {
    :conditions => "topic_video_segments.score >= 0"
  }

  named_scope :related_to_topics, lambda {|topic_ids|
    {
      :select =>
        "topics.*, " +
        "#{VideoSegment.match_score} score, " +
        "COUNT(DISTINCT videos.id) video_count",
      :joins => [
        "INNER JOIN topic_video_segments tvs2 ON tvs2.video_segment_id = topic_video_segments.video_segment_id"],
      :conditions => [
        "topics.id NOT IN (?) AND tvs2.topic_id IN (?)", topic_ids, topic_ids],
      :group => "topics.id"
    }
  }

  alias_scope :related_to_all_topics, lambda {|topic_ids|
    topic_count = topic_ids.is_a?(Array) ? topic_ids.count : 1
    Topic.related_to_topics(topic_ids).scoped(
      :select =>
        "topics.*, " +
        "#{VideoSegment.match_score} score, " +
        "COUNT(DISTINCT videos.id) video_count" +
        "COUNT(DISTINCT topics.id) topic_count",
      :having =>
        ["topic_count = ?", topic_count]
    )
  }

  def after_create
    generate_guid
  end

  before_save :set_sort_name
  def set_sort_name
    self.sort_name = name.sub(/^(the|a)\s+(.*)/i, '\2, \1')
  end

  # Virtual attribute for selected state
  attr_accessor :is_selected

  def generate_guid
    # Generate a GUID
    require 'digest/md5'
    update_attribute :guid, (Digest::MD5.hexdigest self.id.to_s + self.name)
  end

  # Return the topic description. If none is set, delegate to entity identifiers.
  def attributed_description
    text = self[:description]
    unless text.nil? || text.empty?
      return {:text => self[:description]}
    end
    self.entity_identifiers.each do |ident|
      next if ident.description.blank?
      return {:text => ident.description, :entity_db => ident.entity_db}
    end
    nil
  end
  def description
    att = attributed_description
    return nil if att.nil?
    return att[:text] || nil
  end

  begin
    alias_scope :featured, lambda {
      Topic.in_playlist(nil, 'featured-topics')
    }
    def is_featured
      self.class.featured_topics_by_id[self.id].present?
    end
  end

  def self.featured_topics_playlist
    @@featured_topics_playlist ||= Playlist.scoped_by_user_id(nil).scoped_by_permalink(:"featured-topics").first
  end

  def is_featured= value
    featured_topics = self.class.featured_topics_playlist
    if value == true || value.is_a?(String) && value.to_i == 1
      featured_topics.add self
    else
      featured_topics.remove self
    end
  end

  # Virtual column for admin
  def live_video_segment_count
    self.video_segments.live.count
  end

  def self.matching_topics text, omit = nil
    topics = []
    return topics if (text ||= '').empty?

    conditions = []
    text.downcase.scan(/\w+/) do |word|
      conditions << "name LIKE '%#{word}%'"
    end

    conditions = conditions.join ' OR ' unless conditions.nil?
    unless conditions.empty?
      topics = self.find :all, :conditions => conditions
    end

    unless omit.nil? || omit.empty?
      # Make a dummy collection of tvs instances for filtering
      tvss = topics.collect{|t| TopicVideoSegment.new :topic => t}
      tvss = self.filter_ommitted tvss, omit
      topics = tvss.collect{|t| t.topic}
    end

    topics
  end

  def self.fetch_suggested_topics text, omit_topics = nil
    # This is a class method since the segment may not exist in the db yet
    return nil if text.nil? || text.empty?

    tvss = []
    # Hit each API in a separate thread
    apis = SemanticApi.live.find :all, :conditions => {:name => ['Zemanta']}
    threads = []
    apis.each do |api|
      threads << Thread.new(api) do |thread_api|
        begin
          result = nil
          if api.is_a? ZemantaApi
            result = api.query :text => text, :only => {:topics => true}
            next unless result[:status] == :success
            Thread.current[:tvss] = self.filter_ommitted result[:topic_video_segments], omit_topics
          else
            result = api.query :text => text
            next unless result[:status] == :success
            Thread.current[:tvss] = self.filter_ommitted result[:topic_video_segments]
          end
        rescue => error
          Thread.current[:rescued] = error
        end
      end
    end
    # Join and check for exceptions
    threads.each do |thread|
      thread.join
      next unless thread[:rescued].present?
      raise thread[:rescued]
    end
    threads.each do |thread|
      tvss.concat thread[:tvss] unless thread[:tvss].nil? || thread[:tvss].empty?
    end

    tvss
  end

  # Filter out elements of tvss (collection of tvs instances) based on omit criteria.
  def self.filter_ommitted tvss, omit_topics
    # Check for topic id's to omit
    unless omit_topics.nil? || omit_topics.empty? || tvss.nil? || tvss.empty?
      # Make a hash to make lookups fast
      omits_by_id = {}
      omits_by_ident = {}
      omit_topics.each do |key, omit_topic|
        omits_by_id[omit_topic['id'].to_i] = true
        omit_topic['entity_identifiers'].each do |entity_db_id, identifier|
          omits_by_ident[entity_db_id.to_i] ||= {}
          omits_by_ident[entity_db_id.to_i][identifier] = true
        end unless (omit_topic['entity_identifiers'] || nil).nil? || omit_topic['entity_identifiers'].empty?
      end

      tvss.delete_if do |tvs|
        result = false
        if tvs.topic_id.nil?
        elsif omits_by_id[tvs.topic_id]
          result = true
        else
          tvs.topic.entity_identifiers.each do |ident|
            result = (omits_by_ident[ident.entity_db_id.to_s][ident.identifier] rescue nil)
            break if result
          end unless tvs.topic.entity_identifiers.empty?
        end
        result
      end
    end

    tvss
  end

  # Fill the topic with blank records for any entity_db's that it isn't associated with
  def fill_entity_identifiers
    entity_dbs = EntityDb.live
    idents_by_entity_db_id = []
    self.entity_identifiers.each {|i| idents_by_entity_db_id[i.entity_db_id] = i}
    entity_dbs.each do |entity_db|
      next if idents_by_entity_db_id[entity_db.id]
      # Create a provisional dummy record for additions
      self.entity_identifiers.build :entity_db => entity_db
    end
  end

  def self.obfuscate_topic_ids topic_ids
    require 'base64'
    topics = topic_ids.collect{|i| i.to_i}.join(',')
    topics = CGI.escape(Base64.encode64(topics)) if self.obfuscate?
    topics
  end

  def self.deobfuscate_topic_ids str
    require 'base64'
    str = Base64.decode64(CGI.unescape(str)) if self.obfuscate?
    parse_csv(str).collect{|i| i.to_i}
  end

  def self.obfuscate?
    # Set to false for debug
    true
  end

  def self.featured_topics_by_id
    unless defined? @@featured_topics
      @@featured_topics = {}
      items = PlaylistItem.playlist_user_id_eq(nil).
        playlist_permalink_eq('featured-topics')
      topics_by_id = self.find_all_by_id(items.collect{|i| i.playlistable_item_id}).
        inject({}) {|h, topic| h.merge(topic.id => topic)}
      items.each do |item|
        @@featured_topics[item.playlistable_item_id] = topics_by_id[item.playlistable_item_id]
      end
    end
    @@featured_topics
  end

  # sunspot (solr) fulltext searching
  # http://wiki.github.com/outoftime/sunspot/setting-up-classes-for-search-and-indexing

  searchable do
    text :name, :default_boost => 2
    text :description
    string :name, :stored => true
    boolean :live, :using => :live?
  end

end



# == Schema Information
#
# Table name: topics
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  sort_name   :string(255)
#  category    :string(255)
#  description :text
#  active      :boolean(1)      default(FALSE), not null
#  deleted     :boolean(1)      default(FALSE), not null
#  guid        :string(255)
#  permalink   :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

