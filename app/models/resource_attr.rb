class ResourceAttr < ActiveRecord::Base
  
  belongs_to :resource, :polymorphic => true

  validates_presence_of :name, :resource_id, :resource_type
  validates_uniqueness_of :name, :scope => [:resource_type, :resource_id]
end

# == Schema Information
#
# Table name: resource_attrs
#
#  id            :integer(4)      not null, primary key
#  resource_id   :integer(4)
#  resource_type :string(40)
#  name          :string(40)
#  value         :text
#  created_at    :datetime
#  updated_at    :datetime
#

