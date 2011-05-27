class ContentType < ActiveRecord::Base
  has_many :external_contents
  has_many :content_type_semantic_apis
  has_many :semantic_apis, :through => :content_type_semantic_apis

  named_scope :ordered, :order => 'display_order ASC'
  named_scope :live, :conditions => {:active => true, :deleted => false}

  validates_uniqueness_of :display_order

  def css_class
    name.titleize.gsub(/ /, '').underscore.dasherize
  end

  def before_validation_on_create
    # Renumber display_order as necessary
    self.class.update_all 'display_order = display_order + 1', ['display_order >= ?', self.display_order || 0],
      :order => 'display_order DESC'
  end

  def self.live_content_types_by_id
    return @@live_content_types_by_id if defined? @@live_content_types_by_id

    @@live_content_types_by_id = {}
    self.live.each {|c| @@live_content_types_by_id[c.id] = c}
    @@live_content_types_by_id
  end

  def self.live_video_content_type_ids
    return @@video_content_type_ids ||= self.live.each.select{|i| i.name == 'Related Videos'}.collect{|i| i.id}
  end

end


# == Schema Information
#
# Table name: content_types
#
#  id            :integer(4)      not null, primary key
#  name          :string(255)
#  description   :text
#  item_type     :string(255)
#  display_order :integer(4)      default(0), not null
#  active        :boolean(1)      default(FALSE), not null
#  deleted       :boolean(1)      default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

