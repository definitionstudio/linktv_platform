class TruveoApi < SemanticApi

  def query args
    begin
      return nil unless args[:text] && args[:text].is_a?(String) && !args[:text].empty?

      # Defaults
      params = {
        "method" => 'truveo.videos.getVideos',
        "format" => "json",
        "appid" => APP_CONFIG[:apis][:truveo][:appid],
        'limit' => APP_CONFIG[:apis][:truveo][:limit] || 10
      }

      # Apply DB overrides
      db_params = self.query_params.nil? ? {} : JSON.parse(self.query_params)
      params.merge! db_params

      args[:omit_identifiers] ||= {}

      and_keywords = []
      not_keywords = []
      or_keywords = []
      args[:topics_data].each do |topic_data|
        score = topic_data['score'].to_i
        or_keywords << "\"#{topic_data['name'].gsub(/"/, '\"')}\"" if score > 0
        not_keywords << "-\"#{topic_data['name'].gsub(/"/, '\"')}\"" if score == -1

        # Require keywords with weights >= threshold
        if score >= APP_CONFIG[:apis][:config][:emphasis_threshold]
          and_keywords << "\"#{topic_data['name'].gsub(/"/, '\"')}\"" unless score == 0
        end
      end

      if and_keywords.empty? && or_keywords.empty?
        return {
          :status => "error",
          :message => "No keywords selected"
        }
      end

      params['query'] = [[and_keywords.join(' '), not_keywords.join(' ')].join(' '), or_keywords.join(' OR ')].join(' ')
      params['results'] = args[:limit] if args[:limit].present?

      uri = URI.parse(self.url)
      response = Net::HTTP.get_response uri.host, uri.path.concat(query_string(params))
      unless PRODUCTION_MODE
        logger.info 'TruveoApi::query ' + params.inspect
        logger.info 'TruveoApi::query response code ' + response.code
        logger.info 'TruveoApi::query response body ' + response.body
      end

      body = JSON.parse response.body

      if response.code != '200' || (body['response']['status']['code'] rescue nil) != 200
        return {
          :status => "error",
          :response_code => response.code,
          :message => body
        }
      end

      result = {
        :status => nil
      }

      # This API really only accepts the one content type, vidoe
      content_type = self.content_types[0]
      result[:content_types] ||= {}
      result[:content_types][content_type.id] = []

      high_score = body['response']['data']['results']['videoSet']['videos'].collect{|x| x['textRelevancy'].to_f}.max rescue nil
      return result if high_score.nil?

      results_by_identifier = {}
      videos = (body['response']['data']['results']['videoSet']['videos'] rescue [])
      videos.each do |item|
        # These are provision records only, and will only be saved if they are submitted by the client.
        # Since we're using a non-URL for the identifier, we add the semantic API id for scoping purposes.
        identifier = "#{self.id}:#{item['canonicalId']}"
        next if results_by_identifier[identifier] || nil
        results_by_identifier[identifier] = true;

        content_source = ContentSource.find_or_create_by_url(item['channelUrl'])

        result[:content_types][content_type.id] << ExternalContent.new({
          :data => item.to_json,
          :name => item['title'] || nil,
          :description => item['description'] || nil,
          :url => item['videoUrl'] || nil,
          :identifier => identifier,
          :duration => item['runtime'] || nil,
          :published_at => item['dateProduced'] || nil,
          :content_source => content_source,
          :score => (item['textRelevancy'].to_f / high_score * 100).to_i || nil,
          :content_type => content_type,
          :semantic_api => self,
          :active => true,
          :deleted => false
        }) unless args[:omit_identifiers][identifier].present?
      end

      result[:status] = :success
      return result
    rescue => error
      raise
    end
  end

  # Extract the thumbnail URL from item data
  def self.thumbnail_url json
    item_data = JSON.parse(json)
    return false if item_data.nil? || item_data.empty?
    url = item_data['thumbnailURLLarge'] || nil
    url = item_data['thumbnailURL'] || nil if url.blank?
    url = nil? if url.blank?
    url
  end

end

# == Schema Information
#
# Table name: semantic_apis
#
#  id           :integer(4)      not null, primary key
#  type         :string(255)
#  name         :string(255)
#  url          :string(1024)
#  query_params :string(1024)
#  quota_config :string(1024)
#  active       :boolean(1)      default(FALSE), not null
#  deleted      :boolean(1)      default(FALSE), not null
#  lifetime     :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

