class Page < ActiveRecord::Base
  
  named_scope :live, :conditions => {:active => true, :deleted => false}

  validates_presence_of :name
  validates_uniqueness_of :path

  def before_validation
    if path.blank?
      self.path = nil
    end
  end

end


# == Schema Information
#
# Table name: pages
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     not null
#  path       :string(255)
#  content    :text            default(""), not null
#  active     :boolean(1)      default(FALSE), not null
#  deleted    :boolean(1)      default(FALSE), not null
#  created_at :datetime
#  updated_at :datetime
#

