class Country < ActiveRecord::Base
  has_and_belongs_to_many :restricted_videos, :class_name => 'Video', :join_table => :geo_restrictions
end

# == Schema Information
#
# Table name: countries
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  iso3166_1_alpha_2 :string(2)
#  iso3166_1_alpha_3 :string(3)
#  iso3166_1_numeric :integer(4)
#  created_at        :datetime
#  updated_at        :datetime
#

