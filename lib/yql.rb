class Yql

  def self.query query
    require 'open-uri'
    
    query_params = {
      :q => query,
      :env => "http://datatables.org/alltables.env",
      :format => 'json'
    }
    
    uri = URI.parse "http://query.yahooapis.com/v1/public/yql"

    # Yahoo doesn't want + for spaces
    query_string = query_string(query_params).gsub(/\+/, '%20')
    
    response = Net::HTTP.get_response uri.host, uri.path.concat(query_string)

    response_code = response.code rescue 'undefined'
    if response_code != '200'
      raise "YQL query failed with response code #{response_code}"
    end

    begin
      result = JSON.parse response.body
    rescue
      raise "YQL query contained invalid response \"#{response.body}\""
    end

    result
  end

  def self.geoip ip
    begin
      response = self.query "SELECT * FROM pidgets.geoip WHERE ip='#{ip}'"
    rescue => exc
      raise "YQL GeoIP query failed: #{exc.message}"
    end

    begin
      result = response['query']['results']['Result']
    rescue
      raise "YQL GeoIP query returned invalid response #{response.to_json}"
    end

    country = nil
    if result['country_code3'].present?
      country = Country.find_by_iso3166_1_alpha_3 result['country_code3']
    elsif result['country_code2'].present?
      country = Country.find_by_iso3166_1_alpha_2 result['country_code2']
    else
      raise "GeoIP lookup for #{ip} did not return country code"
    end

    unless country.present?
      raise "GeoIP lookup for #{ip} found no matching Country"
    end

    country
  end

end
