class VideoPlayStat < ActiveRecord::Base
  belongs_to :video
  belongs_to :video_segment
  belongs_to :user

  validates_presence_of :video_id, :ip

  named_scope :ordered, :order => 'created_at DESC'
end



# == Schema Information
#
# Table name: video_play_stats
#
#  id               :integer(4)      not null, primary key
#  video_id         :integer(4)
#  video_segment_id :integer(4)
#  user_id          :integer(4)
#  ip               :string(255)
#  http_user_agent  :string(255)
#  http_referer     :string(255)
#  created_at       :datetime
#

