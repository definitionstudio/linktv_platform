class ZemantaApi < SemanticApi
  
  # Translate URL as necessary
  def parse_url url
    if matches = url.match(/^http:\/\/r\.zemanta\.com\/\?u=([^&]+)/)
      return CGI.unescape matches[1]
    end
    url
  end

  def query args
    begin
      return nil unless args[:text] && args[:text].is_a?(String) && !args[:text].empty?

      topics_only = (args[:only].present? && args[:only].include?(:topics))

      # Defaults
      params = {
        "format" => "json",
        "method" => "zemanta.suggest",
        "return_rdf_links" => 1,
        "return_images" => 0,
        "api_key" => APP_CONFIG[:apis][:zemanta][:api_key],
        'articles_limit' => APP_CONFIG[:apis][:zemanta][:limit] || 10
      }

      # Apply DB overrides
      db_params = self.query_params.nil? ? {} : JSON.parse(self.query_params)
      params.merge! db_params

      params['text'] = args[:title].present? ? args[:title].dup : '' # dup since we'll be appending to this string
      params['text'] << "\r\n\r\n"
      args[:topics_data] ||= []
      args[:topics_data].each do |topic_data|
        score = topic_data['score'].to_i
        next unless score > 0
        (score.to_f / 50).round.times do
          params['text'] << topic_data['name'] + "\r\n"
        end
      end
      params['text'] << "\r\n"
      params['text'] << args[:text].gsub(/[\r\n]+/, ' ')

      args[:only] ||= {}
      args[:omit_identifiers] ||= {}

      response = Net::HTTP.post_form URI.parse(self.url), params
      unless PRODUCTION_MODE
        logger.info 'ZemantaApi::query ' + params.inspect
        logger.info 'ZemantaApi::query response code ' + response.code
        logger.info 'ZemantaApi::query response body ' + response.body
      end

      body = JSON.parse(response.body)

      if response.code != '200'
        return {
          :status => "error",
          :response_code => response.code,
          :message => body
        }
      end

      result = {
        :status => nil
      }

      #
      # External (Related) Content
      #

      # Loop through the content types defined for this API
      high_score = 0

      if !topics_only

        logger.debug('ZemantaApi::query processing ARTICLES')

        self.content_type_semantic_apis.each do |xref|
          content_type = xref.content_type

          next if (args[:only] || nil) && (args[:only][:content_type_ids] || nil) && !args[:only][:content_type_ids].include?(xref.content_type_id)

          result[:content_types] ||= {}
          result[:content_types][content_type.id] = []

          next if body['articles'].nil?

          results_by_identifier = {}

          body['articles'].each do |item|

            url = self.parse_url(item['url'])
            identifier = url
            next if results_by_identifier[identifier] || nil
            results_by_identifier[identifier] = true;
            content_source = ContentSource.find_or_create_by_url url

            result[:content_types][content_type.id] << ExternalContent.new({
              :data => item.to_json,
              :name => item['title'],
              # Note: currently stripping tags, which appear to be <em> from Zemanta to highlight matching terms.
              # Consider replacing this markup with a span/class for display purposes in the future.
              :description => strip_xml_tags(item['text_highlight']),
              :url => url,
              :identifier => identifier,
              :published_at => item['published_datetime'],
              :content_source => content_source,
              :score => item['confidence'],
              :content_type => content_type,
              :semantic_api => self,
              :active => true,
              :deleted => false
            }) unless args[:omit_identifiers][identifier].present?

            high_score = [high_score, item['confidence']].max
          end
          
          result[:content_types][content_type.id].each do |item|
            item[:score] = (item[:score] / high_score * 100).to_i
          end
        end
      end

      #
      # Topics
      #

      if topics_only && !(body['markup']['links'] || nil).nil? && !body['markup']['links'].empty?

        logger.debug('ZemantaApi::query processing TOPICS')

        freebase_api = EntityDb.find_by_name('Freebase')
        result[:topic_video_segments] = []
        topic_names = {}

        #
        # Embedded links - disambiguated by Zemanta
        #

        entity_db_match = false
        high_score = body['markup']['links'].collect{|x| x['confidence']}.max
        body['markup']['links'].each do |link|
          topic = nil
          targets = link['target']
          targets.each do |target|
            break unless topic.nil?
            next unless (entity_db = EntityDb.entity_db_by_uri target['url'])
            entity_db_match = true

            # The identifier matches the criteria for one of the EntityDbs
            entity_identifier = EntityIdentifier.find_by_identifier(entity_db.uri_to_identifier target['url'])
            if entity_identifier
              # Found a matching entity, add a reference to it
              topic = entity_identifier.topic
              topic_names[topic.name] = true
              result[:topic_video_segments] << TopicVideoSegment.new({
                :topic => topic,
                :score => (link['confidence'] / high_score * 100).to_i,
                :semantic_api => self
              })
            end
          end

          if topic.nil? && entity_db_match
            # No matching entity found. Create a provisional entity_identifier and topic
            # Override the order Zemanta returns entities, i.e. prioritize freebase first.
            prioritized_targets = []
            targets.each do |target|
              if (identifier = freebase_api.match target['url'])
                prioritized_targets.unshift target
              else
                prioritized_targets << target
              end
            end

            prioritized_targets.each do |target|
              next unless (entity_db = EntityDb.entity_db_by_uri target['url'])
              if topic.nil?
                topic = Topic.new({
                  :name => target['title'],
                  :active => true})
                topic_names[topic.name] = true;
                result[:topic_video_segments] << TopicVideoSegment.new({
                    :topic => topic,
                    :score => (link['confidence'] / high_score * 100).to_i,
                    :semantic_api => self
                })
              end
              entity_identifier = EntityIdentifier.new({
                :topic => topic,
                :entity_db => entity_db,
                :identifier => entity_db.uri_to_identifier(target['url']),
                :data => target.to_json})
              topic.entity_identifiers << entity_identifier
            end
          end
        end

        #
        # Keywords - non-disambiguated by Zemanta (must use zemanta.suggest to return)
        #
        high_score = body['keywords'].collect{|x| x['confidence']}.max
        body['keywords'].each do |keyword|
          topic = nil
          next if topic_names[keyword['name']]
          topic = Topic.new :name => keyword['name'], :active => true if topic.nil?
          result[:topic_video_segments] << TopicVideoSegment.new({
              :topic => topic,
              :score => (keyword['confidence'] / high_score * 100).to_i,
              :semantic_api => self
          })
        end

        result[:topic_video_segments].sort {|x, y| y.score <=> x.score}
      end

      result[:status] = :success
      result
    rescue => error
      raise
    end
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

