class ExternalContent < ActiveRecord::Base

  include Linktv::Platform::CommonThumbnail
  
  disable_deletes # Enforce use of destroy so callback are hit
  belongs_to :content_source
  belongs_to :video_segment
  belongs_to :semantic_api
  belongs_to :content_type

  named_scope :active, :conditions => {:active => true}
  named_scope :deleted, :conditions => {:deleted => true}
  named_scope :sticky, :conditions => {:sticky => true}
  named_scope :static, :conditions => ['sticky OR external_contents.deleted OR semantic_api_id IS NULL'] # These should not be deleted automatically
  named_scope :dynamic, :conditions => ['!sticky AND !external_contents.deleted AND semantic_api_id IS NOT NULL'] # Deletable when reloading fresh content
  named_scope :manual, :conditions => {:semantic_api_id => nil}

  named_scope :live, :conditions => {:active => true, :deleted => false}
  def live?; active && !deleted end

  begin
    # Note: not DRY, keep weighted_score method in sync with :with_weighted_score
    def weighted_score
      if self[:weighted_score] || nil
        return self[:weighted_score]
      elsif score.nil?
        return nil
      else
        return score * (content_source.present? ? content_source.weight : 1)
      end
    end
    named_scope :with_weighted_score,
      :select =>
        "external_contents.*, (score * IF(content_sources.weight IS NULL, 1, content_sources.weight)) weighted_score",
      :joins => self.left_outer_joins(:content_source)
  end
  
  # Note: the following named scopes require the with_weighted_score to be used in front of them
  named_scope :ordered,
    :order => '(semantic_api_id IS NULL) DESC, sticky DESC, display_order ASC, weighted_score DESC'
  named_scope :ordered_for_admin,
    :order => 'external_contents.deleted ASC, (semantic_api_id IS NULL) DESC, sticky DESC, display_order ASC, weighted_score DESC'
  named_scope :include_content_sources, :include => :content_source
  named_scope :include_semantic_api, :include => :semantic_api
  named_scope :include_thumbnail, :include => :thumbnail

  named_scope :most_recent, :order => 'created_at DESC', :limit => 1

  validates_presence_of :name, :url

  # TODO: optimize, only validate when user is entering a new url manually!

  def before_validation_on_create
    # Link video if necessary
    # video/video_segment may be nil if content is provisional
    self.video_id = video_segment.video_id if video_id.nil? unless video_segment.nil?
  end

  def before_validation
    self.url = (self.url || '').strip
  end

  def before_create
    unless self.content_source.present? || self.url.blank?
      self.content_source = ContentSource.find_or_create_by_url(self.url)
    end
  end

  def after_create
    download_thumbnail
  end

  # Sort order
  def <=> obj
    val = 0
    return val if (val = (self.manual ? 0 : 1) <=> (obj.manual ? 0 : 1)) != 0
    return val if (val = (self.display_order || 0) <=> (obj.display_order || 0)) != 0
    return val if (val = (self.deleted ? 1 : 0) <=> (obj.deleted ? 1 : 0)) != 0
    return val if (val = (self.sticky ? 0 : 1) <=> (obj.sticky ? 0 : 1)) != 0
    return val if (val = (obj.weighted_score || 0) <=> (self.weighted_score || 0)) != 0
    0
  end

  def static
    sticky || deleted || manual
  end

  def dynamic
    !static
  end

  def manual
    semantic_api_id.nil?
  end

  def attribution
    return nil if self.content_source.nil?
    {
      :name => self.content_source.name,
      :url => self.content_source.base_url
    }
  end

  attr_accessor :published_date, :published_time
  def published_date= value
    if published_at.present?
      self.published_at = published_at - published_at.midnight + Time.parse(value).utc.midnight
    else
      self.published_at = Time.parse(value).utc.midnight
    end
  end
  def published_time= value
    # TODO verify formats are parseable, i.e. HH:MM
    self.published_at = 0 if published_at.nil?
    time = Time.parse(value).utc
    self.published_at = published_at.midnight + (time - time.midnight).to_i
  end

  # Fetch external content
  def self.query title, text, topics_data, args = {}
    # This is a class method since the segment may not exist in the db yet
    return nil if (title.nil? || title.empty?) && (text.nil? || text.empty?) && (topics_data.nil? || topics_data.empty?)

    contents_by_id = {}
    content_types = (args[:content_type_id] || nil) ? [ContentType.find(args[:content_type_id])] : ContentType.live # Default to all

    # Hit each ContentType/API in a separate thread
    begin
      threads = []
      semantic_apis = {}
      content_types_by_api = {}
      content_types.each do |content_type|
        content_type.semantic_apis.each do |api|
          semantic_apis[api.id] = api
          (content_types_by_api[api.id] ||= []) << content_type
        end
      end

      semantic_apis.each do |api_id, api|
        content_type_ids = content_types_by_api[api_id].collect {|c| c.id}
        threads << Thread.new(api) do |thread_api|
          begin
            Thread.current[:api] = api # For debug
            Thread.current[:content_types] = {}
            logger.info "*** EXTERNAL CONTENT API QUERY [" + Time.now.to_s + "] " + thread_api.name
            query = thread_api.query(
              :title => title,
              :text => text,
              :topics_data => topics_data,
              :omit_identifiers => args[:omit_identifiers] || nil,
              :only => {:content_type_ids => content_type_ids}
            )
            unless query.nil? || query[:status] == :success
              Thread.current[:content_types] = {}
              next
            end
            Thread.current[:content_types] = query[:content_types] unless query.nil? || query[:content_types].nil?
          rescue Exception => error
            Thread.current[:rescued] = error
            logger.error error.inspect
          end
        end
      end
      threads.each do |thread|
        thread.join
        next if thread[:rescued].present?
        thread[:content_types].each do |content_type_id, contents|
          (contents_by_id[content_type_id] ||= []).concat contents unless contents.nil? || contents.empty?
        end unless thread[:content_types].nil? || thread[:content_types].empty?
      end
    end
    contents_by_id
  end

  def thumbnail_url
    return nil if self.data.blank?
    return nil unless self.semantic_api.class.respond_to? :thumbnail_url
    self.semantic_api.class.thumbnail_url self.data
  end

  def download_thumbnail
    return thumbnail unless thumbnail.nil?

    url = thumbnail_url
    return nil if url.nil?

    self.thumbnail = Image.create! :filename => File.basename(url), :source_url => url
    return false unless thumbnail.download
    if save
      return thumbnail
    else
      self.thumbnail.delete
      return false
    end
  end

  # Determine if a content record is a duplicate (in the list) based on the name (title)
  # Occurrences of the same name after the first are tagged as such.
  attr_accessor :is_duplicate
  def self.check_for_duplicates collection
    # Check for duplicates
    return if collection.nil? || collection.empty?
    by_name = {}
    collection.each do |content|
      content.is_duplicate = false
      key = content.name.downcase.gsub(/[^\w]+/, ' ').strip
      if by_name[key].present?
        content.is_duplicate = true
      else
        by_name[key] = true
      end
    end
  end

  attr_accessor :has_low_score
  def self.check_scores collection
    return if collection.nil? || collection.empty?
    collection.each do |content|
      next if content.semantic_api_id.nil?
      next unless content.weighted_score.to_i < APP_CONFIG[:apis][:config][:low_score_threshold]  # TODO: dynamic threshold
      content.has_low_score = true
    end
  end

  attr_accessor :is_filtered_by_topic
  def self.check_titles collection, topics_data
    return if collection.nil? || collection.empty?
    topic_names = []
    topics_data.each do |topic_data|
      next unless topic_data['score'].to_i == -1
      topic_names << "\\b#{topic_data['name']}\\b"
    end
    return if topic_names.empty?

    topic_regex = topic_names.join('|')

    collection.each{|c| c.is_filtered_by_topic = true if c.name.match(/#{topic_regex}/i)}
  end

  # Check which items in a collection should be filtered out, for having duplicate
  # names, or low scores.
  # Sets the filtered? attribute only, does not remove elements from the collection,
  # as the view may choose to display the item differently.
  def self.filter_collection collection, topics_data
    self.check_for_duplicates collection
    self.check_scores collection
    self.check_titles collection, topics_data
  end

  def filtered?
    !self.sticky && (self.is_duplicate || self.has_low_score || self.is_filtered_by_topic)
  end

  def is_video
    return ContentType.live_video_content_type_ids.include? self.content_type_id
  end


  # sunspot (solr) fulltext searching
  # http://wiki.github.com/outoftime/sunspot/setting-up-classes-for-search-and-indexing

  searchable do
    text :name, :default_boost => 2
    text :description
    integer :content_type_id, :references => ContentType
    boolean :live, :using => :live?
    # TODO: exclude duplicates
  end

end


# == Schema Information
#
# Table name: external_contents
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  description       :text
#  display_order     :integer(4)
#  url               :string(1024)
#  data              :text
#  video_segment_id  :integer(4)      not null
#  content_type_id   :integer(4)      not null
#  semantic_api_id   :integer(4)
#  content_source_id :integer(4)
#  score             :decimal(10, 8)
#  sticky            :boolean(1)      default(FALSE), not null
#  published_at      :datetime
#  expires_at        :datetime
#  active            :boolean(1)      default(FALSE), not null
#  deleted           :boolean(1)      default(FALSE), not null
#  video_id          :integer(4)      not null
#  identifier        :string(1024)
#  duration          :integer(4)
#  created_at        :datetime
#  updated_at        :datetime
#

