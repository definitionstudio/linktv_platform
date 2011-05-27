class DaylifeApi < SemanticApi

  def query args
    begin
      require 'digest/md5'

      access_key = APP_CONFIG[:apis][:daylife][:accesskey]
      secret_key = APP_CONFIG[:apis][:daylife][:secretkey]

      # Defaults
      params = {
        'accesskey' => access_key,
        'limit' => APP_CONFIG[:apis][:daylife][:limit] || 10
      }

      # Apply DB overrides
      db_params = self.query_params.nil? ? {} : JSON.parse(self.query_params)
      params.merge! db_params

      args[:omit_identifiers] ||= {}

      result = {
        :status => nil
      }

      if (args[:topics_data] || nil).nil? || args[:topics_data].empty?
        result[:status] = :empty
        return result
      end

      weighted_keywords = []
      args[:topics_data].each do |topic_data|
        # Score of zero means we omit the topic from queries
        score = topic_data['score'].to_i
        weighted_keywords << "\"#{topic_data['name'].gsub(/"/, '\"')}\"^#{score}" if score > 0
      end
      query = weighted_keywords.join(' OR ')

      params.merge!({
        'query' => query,
        'signature' => Digest::MD5.hexdigest(access_key + secret_key + query)})
      params['limit'] = args[:limit] if args[:limit].present?

      uri = URI.parse(self.url)
      response = Net::HTTP.get_response uri.host, uri.path.concat(query_string(params))
      unless PRODUCTION_MODE
        logger.info 'DaylifeApi::query ' + params.inspect
        logger.info 'DaylifeApi::query response ' + response.code
        logger.info 'DaylifeApi::query response body ' + response.body
      end

      if response.code != '200'
        return {
          :status => "error",
          :response_code => response.code,
          :message => body
        }
      end

      response_body = JSON.parse response.body

      # Loop through the content types defined for this API
      # Note: this API class only implements the article type
      results_by_identifier = {}
      self.content_type_semantic_apis.each do |xref|
        content_type = xref.content_type

        result[:content_types] ||= {}
        result[:content_types][content_type.id] = []

        return result if (response_body['response']['payload']['article'] || nil).nil?

        high_score = response_body['response']['payload']['article'].collect{|x| x['search_score']}.max rescue nil
        return result if high_score.nil?

        response_body['response']['payload']['article'].each do |item|
          # Since we're using a non-URL for the identifier, we add the semantic API id for scoping purposes.
          identifier = "#{self.id}:#{item['article_id']}"
          next if results_by_identifier[identifier] || nil
          results_by_identifier[identifier] = true;

          # Using source url instead of article url, which may use a URL shortener service
          content_source = ContentSource.find_or_create_by_url item['source']['url'],
            :name => item['source']['name'], :favicon_url => item['source']['favicon_url']

          result[:content_types][content_type.id] << ExternalContent.new({
            :data => item.to_json,
            :name => item['headline'],
            :description => item['excerpt'],
            :url => item['url'],
            :identifier => identifier,
            :published_at => item['timestamp'],
            :content_source => content_source,
            :score => (item['search_score'] / high_score * 100).to_i,
            :content_type => content_type,
            :semantic_api => self,
            :active => true,
            :deleted => false
          }) unless args[:omit_identifiers][identifier].present?
        end
      end

      result[:status] = :success
      result
    end
  rescue => error
    raise
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

