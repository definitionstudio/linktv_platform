class EntityDb < ActiveRecord::Base

  has_many :entity_identifiers

  named_scope :live, :conditions => {:active => true, :deleted => false}

  # May be set to true by subclass.
  # Indicates whether the class provides cacheable entity data, which would be
  # stored in the EntityIdentifier.data attribute.
  def provides_data?
    false
  end

  def self.entity_db_by_uri uri
    return nil if uri.nil? || !uri.is_a?(String) || uri.empty?
    entity_dbs = self.find :all
    entity_dbs.each do |entity_db|
      return entity_db if entity_db.match uri
    end
    nil
  end

  def match uri
    uri.match(self.identifier_regex) ? self.identifier_to_uri(uri) : false
  end

  # Look up an identifier by URI.
  # It may not (and probably does not) yet exist in the DB, otherwise EntityIdentifier.lookup
  # should be called.
  def self.lookup_by_uri uri, options = {}
    entity_db = entity_db_by_uri uri
    return nil unless entity_db
    entity_db.lookup entity_db.uri_to_identifier(uri), options
  end

  def lookup_by_uri uri, options = {}
    lookup uri_to_identifier(uri), options
  end

  def uri_to_identifier uri
    uri # Default implementation
  end

  def identifier_to_uri entity_identifier
    entity_identifier
  end

  # Look up the identifier in DB
  # To be called by derived class, which will then hit the API to find it if necessary
  def lookup identifier, options = {}
    return nil
  end

end

# == Schema Information
#
# Table name: entity_dbs
#
#  id               :integer(4)      not null, primary key
#  type             :string(255)
#  name             :string(255)
#  description      :text
#  url              :string(1024)
#  icon_css_class   :string(255)
#  identifier_regex :string(255)
#  active           :boolean(1)      default(FALSE), not null
#  deleted          :boolean(1)      default(FALSE), not null
#  created_at       :datetime
#  updated_at       :datetime
#

