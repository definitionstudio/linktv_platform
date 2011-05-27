class Region < ActiveRecord::Base
  
  has_many :region_videos
  has_many :videos, :through => :region_videos

  validates_presence_of :name, :code
  validates_uniqueness_of :code
  validates_length_of :code, :in => 1..10, :allow_nil => true

  named_scope :ordered, :order => 'name'

  named_scope :with_video_count, {
    :select => "regions.*, COUNT(DISTINCT videos.id) video_count",
    :group => 'regions.id'
  }

  named_scope :related_to_videos, lambda {|video_ids|
    video_count = video_ids.is_a?(Array) ? video_ids.count : 1
    {
      :select => "regions.*, COUNT(DISTINCT videos.id) video_count",
      :conditions => ["videos.id IN (?)", video_ids],
      :group => "regions.id"
    }
  }

  # Virtual attribute for selected state
  attr_accessor :is_selected

end

# == Schema Information
#
# Table name: regions
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  code       :string(10)
#  created_at :datetime
#  updated_at :datetime
#

