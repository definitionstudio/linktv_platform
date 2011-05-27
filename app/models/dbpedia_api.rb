class DbpediaApi < EntityDb

  def provides_data?
    true
  end

  def uri_to_identifier uri
    uri.gsub(/http:\/\/([^\.]+.)?dbpedia.org\/resource\/(.+)/, '\2')
  end

  def identifier_to_uri identifier
    "http://dbpedia.org/resource/#{identifier}"
  end

  def lookup identifier, options = {}
    result = super identifier, options
    return result unless result.nil?
    
    resource = "http://dbpedia.org/resource/#{identifier}"
    sparql = <<EOQ
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbpedia: <http://dbpedia.org/ontology/>
SELECT ?name ?description ?thumbnail WHERE {
	OPTIONAL {
		<#{resource}> rdfs:label ?name FILTER (LANG(?name) = 'en')
	}
	OPTIONAL {
		<#{resource}> dbpedia:abstract ?description FILTER (LANG(?description) = 'en')
	}
	OPTIONAL {
		<#{resource}> dbpedia:thumbnail ?thumbnail
	}
}
EOQ

    require 'open-uri'
    uri = "http://dbpedia.org/sparql?query=#{CGI::escape(sparql)}&output=json"
    file = open uri, "Referer" => "#{APP_CONFIG[:site][:referrer]}"
    json_text = file.read

    begin
      # Note: ActiveSupport's json decoder appears to choke on unicode.
      data = JSON.parse json_text
    rescue StandardError => error
      # JSON decode error
      # if error == 'Invalid JSON string' ...
      return nil
    end
    return nil unless data

    values = {}
    begin
      data['results']['bindings'].each do |result|
        result.each do |key, obj|
          values[key] = obj['value']
        end
        break
      end
    rescue
    end

    name = values['name'].nil? ? 'n/a' : values['name'];
    description = values['description'].nil? ? 'n/a' : values['description'];
    thumbnail_uri = values['thumbnail'].nil? ? nil : values['thumbnail'];

    # Not using symbols for keys since this will be JSON-encoded and restored later
    result = {
      'entity_db_id' => self.id,
      'identifier' => identifier,
      'uri' => identifier_to_uri(identifier),
      'name' => name,
      'description' => description,
      'thumbnail_uri' => thumbnail_uri
    }
    result
  end

  def autocomplete term
    require 'open-uri'
    url = 'http://lookup.dbpedia.org/api/search.asmx/KeywordSearch'
    query_params = {
      'QueryString' => term,
      'QueryClass' => '',
      'MaxHits' => 10
    }
    uri = URI.parse url
    response = Net::HTTP.get_response uri.host, uri.path.concat(query_string(query_params))

    if response.code != '200'
      return {
        :status => "error",
        :response_code => response.code,
        :message => response.body
      }
    end

    result = {
      :status => nil
    }

    # Remove the attributes that seem to prevent Nokogiri from parsing the XML properly
    body = response.body.sub(/<ArrayOfResult.*>/, '<ArrayOfResult>');

    data = []
    doc = Nokogiri::XML(body)
    doc.xpath('/ArrayOfResult/Result').each do |result|
      data << {
        'label' => result.xpath('Label').text,
        'description' => result.xpath('Description').text,
        'identifier' => result.xpath('URI').text.sub(/http:\/\/dbpedia.org\/resource\//, '')
      }
    end

    result = {
      :status => 'success',
      :data => data
    }
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

