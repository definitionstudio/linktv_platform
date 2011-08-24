class PlaylistItem < ActiveRecord::Base
  
  belongs_to :playlist
  belongs_to :playlistable_item, :polymorphic => true
  symbolize :playlistable_item_type, :in => [:Video, :VideoSegment, :Topic, :ExternalContent]

  validates_uniqueness_of :playlistable_item_id, :scope => [:playlist_id, :playlistable_item_type]

  named_scope :ordered, :order => :display_order

  begin
    acts_as_list :scope => :playlist, :column => 'display_order'
  rescue
    logger.info "acts_as_list not present"
  end

  def to_label
    "#{playlistable_item.class.name.titleize}: #{playlistable_item.name}"
  end

  def before_validation_on_create
    archive_if_necessary
  end

  def filtered?
    return false unless playlistable_item.present?
    return false if playlistable_item.live?
    true
  end

  def set_archive_data_from_attributes attrs
    self.archive_type = attrs[:content_type_name]
    self.archive_data = {
      :name => attrs[:name],
      :description => attrs[:description],
      :url => attrs[:url],
      :publisher_name => attrs[:publisher_name],
      :publisher_url => attrs[:publisher_url],
      :publish_date => attrs[:publish_date]
    }.to_json
  end

  def data
    @data ||= JSON.parse(archive_data)
  end

  def name
    archive_type.present? ? data['name'] : playlistable_item.name
  end

  def attribution
    archive_type.present? ? (data['attribution'] || nil) : nil
  end

  def description
    archive_type.present? ? (data['description'] || nil) : nil
  end

  def url
    archive_type.present? ? (data['url'] || nil) : nil
  end

  private
  def archive_if_necessary
    # For playlistable_items that may be deleted, we archive a subset of the data in JSON
    # Note: This must be called before validation, and again "before_create",
    #  since Rails seems to reset the assocation in between.
    return unless self.archive_type.blank? # Already archived
    if playlistable_item_type == :ExternalContent
      item = self.playlistable_item
      self.set_archive_data_from_attributes(item.attributes.merge({
        :content_type_name => item.content_type.name,
        :publisher_name => item.content_source.name,
        :publisher_url => item.content_source.base_url,
        :publish_date => item.content_published_at.to_s(:db)
      }))
    end
  end
  
end





# == Schema Information
#
# Table name: playlist_items
#
#  id                     :integer(4)      not null, primary key
#  playlist_id            :integer(4)
#  display_order          :integer(4)
#  playlistable_item_type :string(40)
#  playlistable_item_id   :integer(4)
#  comment                :string(255)
#  archive_type           :string(255)
#  archive_data           :text
#  created_at             :datetime
#  updated_at             :datetime
#

