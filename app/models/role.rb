class Role < ActiveRecord::Base
  
  has_and_belongs_to_many :users

  validates_presence_of :name
  validates_uniqueness_of :name
end

# == Schema Information
#
# Table name: roles
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)     not null
#  description :text
#  active      :boolean(1)      default(FALSE), not null
#  deleted     :boolean(1)      default(FALSE), not null
#  created_at  :datetime
#  updated_at  :datetime
#

