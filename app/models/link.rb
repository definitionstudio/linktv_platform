class Link < ActiveRecord::Base
  
  belongs_to :page

  symbolize :group, :in => [:footer]

  named_scope :ordered, :order => 'display_order ASC'
  named_scope :live, :conditions => {:active => true, :deleted => false}
  named_scope :include_page, :include => :page

  validates_presence_of :name
  validates_uniqueness_of :display_order
  validate do |link|
    link.errors.add "Footer link must contain either a page or a URL" if link.page.nil? && link.url.blank?
  end

  def before_validation_on_create
    # Renumber display_order as necessary
    self.class.update_all 'display_order = display_order + 1', ['display_order >= ?', self.display_order || 0],
      :order => 'display_order DESC'
  end

end


# == Schema Information
#
# Table name: links
#
#  id            :integer(4)      not null, primary key
#  group         :string(255)     not null
#  name          :string(255)     not null
#  display_order :integer(4)      default(0), not null
#  page_id       :integer(4)
#  url           :string(1024)
#  active        :boolean(1)      default(FALSE), not null
#  deleted       :boolean(1)      default(FALSE), not null
#  target        :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

