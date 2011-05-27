class EntityIdentifier < ActiveRecord::Base

  belongs_to :entity_db
  belongs_to :topic

  named_scope :ordered, :order => 'entity_db_id'

  validates_uniqueness_of :identifier, :scope => :entity_db_id, :allow_nil => true
  validates_uniqueness_of :entity_db_id, :scope => :topic_id,
    :message => "is allowed only once per topic"

  def after_create
    # TODO: separate queue for these jobs (separate from uploads/downloads), or at least higher priority
    if !DEVELOPMENT_MODE && self.respond_to?(:send_later)
      send_later :lookup
    else
      lookup
    end
  end

  # Lookup the identifier using the API, and save the data.
  def lookup
    data = self.entity_db.lookup identifier

    unless data.nil?
      self.description = data['description'] unless data['description'].nil?
      self.data = data
    else
      self.failed_lookup_attempts += 1
    end

    # Save even if the lookup fails, ensuring update_at gets set.
    # This ensures an old "bad identifier" doesn't remain the oldest when updating
    # Note: Rails won't change the record if data is the same as before
    self.updated_at = Time.now.utc.to_i

    save!
    data
  end

  def uri
    self.entity_db.identifier_to_uri self.identifier
  end

  # Return JSON-decoded version of data
  def data
    # Use read_attribute to bypass this very method
    data = self.read_attribute :data
    return JSON.parse data unless data.nil?
    nil
  end

  # JSON-encode the data
  def data= value
    if value.nil?
      write_attribute :data, nil
      return
    end
    write_attribute :data, value.to_json
  end

  # cron task
  def self.refresh args = {}
    log = Time.now.to_s + " EntityIdentifier.refresh begin\n"
    args[:limit] ||= 50
    args[:age] ||= 1.day.to_i
    EntityIdentifier.find(:all,
        :conditions => ['(? - UNIX_TIMESTAMP(updated_at)) > ?', Time.now.utc.to_i, args[:age]],
        :limit => args[:limit],
        :order => 'updated_at ASC').each do |ident|
      log << Time.now.to_s << " Lookup EntityIdentifier##{ident.id} #{ident.entity_db.name}: #{ident.identifier} "
      data = ident.lookup
      log += data.nil? ? "(FAILED)\n" : "(SUCCESS)\n"
      sleep 1 # don't flood entity DB API
    end
    log << Time.now.to_s << " EntityIdentifier.refresh end\n"
  end

end

# == Schema Information
#
# Table name: entity_identifiers
#
#  id                     :integer(4)      not null, primary key
#  topic_id               :integer(4)
#  entity_db_id           :integer(4)
#  identifier             :string(1024)
#  description            :text
#  data                   :text
#  failed_lookup_attempts :integer(4)      default(0), not null
#  created_at             :datetime
#  updated_at             :datetime
#

