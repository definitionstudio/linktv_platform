class RegionVideo < ActiveRecord::Base
  belongs_to :video
  belongs_to :region
end

# == Schema Information
#
# Table name: region_videos
#
#  id         :integer(4)      not null, primary key
#  region_id  :integer(4)
#  video_id   :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

