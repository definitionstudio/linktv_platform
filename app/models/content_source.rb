class ContentSource < ActiveRecord::Base
  has_many :external_contents

  named_scope :live, :conditions => {:active => true, :deleted => false}

  validates_numericality_of :weight
  validates_inclusion_of :weight, :in => 0..2, :message => 'must be between 0.0 and 2.0'

  def name
    self[:name] || self[:base_url]
  end

  # returns nil if a source could not be created
  def self.find_or_create_by_url url, args = {}
    # TODO how to handle non-active/deleted sources.
    begin
      host_url = uri_to_hostname url
    rescue URI::InvalidURIError => error
      return nil
    end
    source = self.find_by_base_url host_url

    if source
      # Add name and favicon if they don't already exist and are supplied
      source.name = args[:name] if source.name.nil? && args[:name].present?
      source.favicon_url = args[:favicon_url] if source.favicon_url.nil? && args[:favicon_url].present?
      source.save! if source.changed?
    else
      source = ContentSource.create :base_url => host_url, :active => true,
        :name => args[:name] || nil,
        :favicon_url => args[:favicon_url] || nil
    end

    source
  end

end


# == Schema Information
#
# Table name: content_sources
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  description :text
#  base_url    :string(1024)
#  active      :boolean(1)      default(FALSE), not null
#  deleted     :boolean(1)      default(FALSE), not null
#  weight      :decimal(10, 8)  default(1.0), not null
#  favicon_url :string(1024)
#  created_at  :datetime
#  updated_at  :datetime
#

