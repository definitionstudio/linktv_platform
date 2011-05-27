class SocialActionsApi < SemanticApi

  def query args
    begin

      # Defaults
      params = {
        'limit' => APP_CONFIG[:apis][:socialactions][:limit] || 10
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
      not_keywords = []
      required_keywords = []

      # get entity DB's
      entity_dbs = EntityDb.find(:all)

      entity_dbs_keyed = {}   #rekey by id
      entity_dbs.each do |db|
        entity_dbs_keyed[db.id] = db
      end
      
      args[:topics_data].each do |topic_data|

        # determine which identifier to use (prefer Freebase, should be first in list)
        terms = []
        if(!topic_data['entity_identifiers'].nil?)
          topic_data['entity_identifiers'].each do |identifier|

            db_id = identifier[0].to_i
            entity_db_id = identifier[1]

            next if (entity_dbs_keyed[db_id] || nil).nil?

            if(entity_dbs_keyed[db_id].name.downcase == 'freebase')
              terms << 'http://rdf.freebase.com/ns' + entity_db_id    # match Social Actions URI format (Zemanta result format)
              break
            elsif(entity_dbs_keyed[db_id].name.downcase == 'dbpedia')
              terms << 'http://dbpedia.org/resource/' + entity_db_id
              break
            #else
            #  terms << topic_data['name']
            end
          end
        end

        # add topic name to array
        terms << topic_data['name']

        # Score > threshold means we include the topic in queries
        threshold = 0

        score = topic_data['score'].to_i
        boost = (score > 50) ? (score/10) : 0

        terms.each do |term|
          # excluded terms
          not_keywords << "-\"#{term.gsub(/"/, '\"')}\"" if score == -1
          # Require keywords with weights >= threshold
          if score >= APP_CONFIG[:apis][:config][:emphasis_threshold] && term.match(/^http:\/\//i).nil? && false  # disabled
            required_keywords << "+\"#{term.gsub(/"/, '\"')}\"" unless score == 0
          else
            if boost > 0
              weighted_keywords << "\"#{term.gsub(/"/, '\"')}\"^#{boost}" if score > threshold
            else
              weighted_keywords << "\"#{term.gsub(/"/, '\"')}\"" if score > threshold
            end
          end
        end
      end

      query = [required_keywords.join(' '), weighted_keywords.join(' '), not_keywords.join(' ')].join(' ')

      params.merge!({
        'q' => query
      })
      params['limit'] = args[:limit] if args[:limit].present?

      uri = URI.parse(self.url)
      response = Net::HTTP.get_response uri.host, uri.path.concat(query_string(params))
      unless PRODUCTION_MODE
        logger.info 'SocialActionsApi::query string: ' + query_string(params)
        logger.info 'SocialActionsApi::query ' + params.inspect
        logger.info 'SocialActionsApi::query response ' + response.code
        #logger.info 'SocialActionsApi::query response body ' + response.body
      end

      if response.code != '200'
        return {
          :status => "error",
          :response_code => response.code,
          :message => response.body
        }
      end

      response_body = JSON.parse response.body

      logger.debug(response_body.to_yaml)

      # Loop through the content types defined for this API
      results_by_identifier = {}
      self.content_type_semantic_apis.each do |xref|
        content_type = xref.content_type

        result[:content_types] ||= {}
        result[:content_types][content_type.id] = []

        return result if (response_body || nil).nil?    # empty?

        high_score = response_body.collect{|x| x['action']['score']}.max rescue nil
        return result if high_score.nil?

        logger.debug('SocialActionsApi high_score: ' + high_score.to_s)

        response_body.each do |item|
          action = item['action']
          identifier = action['url']
          next if results_by_identifier[identifier] || nil
          results_by_identifier[identifier] = true;

          # Using source url instead of article url, which may use a URL shortener service
          content_source = ContentSource.find_or_create_by_url action['site']['url'],
            :name => action['site']['name']

          result[:content_types][content_type.id] << ExternalContent.new({
            :data => action.to_json,
            :name => action['title'],
            :description => action['description'],
            :url => action['url'],
            :identifier => identifier,
            :published_at => action['created_at'],
            :content_source => content_source,
            :score => (action['score'] / high_score * 100).to_i,
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

