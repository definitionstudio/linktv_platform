class TopicVideoSegment < ActiveRecord::Base
  
  belongs_to :topic
  belongs_to :video_segment
  belongs_to :video
  belongs_to :semantic_api
  has_many :entity_identifiers

  validates_presence_of :topic_id, :video_id
  validates_presence_of :video_id, :video_segment_id , :unless => lambda {|record|
    # Assuming that new records are being created with nested attributes if the
    # ID is not set, so it will be set upon save.
    record.id == nil
  }

  # Topic may be associated only once per video segment
  validates_uniqueness_of :topic_id, :scope => :video_segment_id

  named_scope :live, :joins => [:video_segment, :topic],
    :conditions => 'topics.active = 1 AND topics.deleted = 0'

  named_scope :ordered, :order => 'score DESC'

  named_scope :include_topics_and_entity_identifiers, :include => [
    {:topic => [
      {:entity_identifiers => [:entity_db]}
    ]}
  ]

  def before_validation_on_create
    self.score ||= self.class.default_score
    # If no video_segment, bypass for now, that will be caught by validations
    self.video_id ||= self.video_segment.video_id unless self.video_segment.nil?
  end

  def self.default_score
    50
  end
end


# == Schema Information
#
# Table name: topic_video_segments
#
#  id               :integer(4)      not null, primary key
#  topic_id         :integer(4)
#  video_segment_id :integer(4)
#  semantic_api_id  :integer(4)
#  score            :integer(4)
#  video_id         :integer(4)
#  created_at       :datetime
#  updated_at       :datetime
#

