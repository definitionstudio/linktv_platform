class FreebaseApi < EntityDb

  def provides_data?
    true
  end

  def uri_to_identifier uri
    uri.gsub(/http:\/\/([^\.]+.)?freebase.com(\/ns)?(.+)/, '\3')
  end

  def identifier_to_uri identifier
    "http://www.freebase.com#{identifier}"
  end

  def lookup identifier, options = {}
    result = super identifier, options
    return result unless result.nil?

    require 'open-uri'
    mode = options[:xrefs] ? 'standard' : 'basic'
    uri = "http://www.freebase.com/experimental/topic/#{mode}?id=#{identifier}"
    file = open uri
    json_text = file.read
    data = JSON.parse(json_text)
    return nil unless data
    entity_data = data[identifier]
    return nil unless entity_data && entity_data[:status.to_s] == '200 OK'
    return nil unless entity_data[:code.to_s] == '/api/status/ok'
    return nil unless entity_result = entity_data[:result.to_s]

    # Not using symbols for keys since this will be JSON-encoded and restored later
    result = {
      'entity_db_id' => self.id,
      'identifier' => identifier,
      'uri' => identifier_to_uri(identifier),
      'name' => entity_result[:text.to_s],
      'description' => entity_result[:description.to_s],
      'thumbnail_uri' => entity_result[:thumbnail.to_s],
      'xrefs' => []
    }

    unless (webpages = entity_result[:webpage.to_s]).nil?
      # Add supported entity identifiers
      webpages.each do |webpage|
        entity_uri = webpage[:url.to_s]
        next unless (entity_db = EntityDb.entity_db_by_uri entity_uri)
        result[:xrefs] << {
          'entity_db_id' => entity_db.id,
          'identifier' => entity_db.uri_to_identifier(entity_uri),
          'uri' => entity_uri
        }
      end
    end

    result
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

