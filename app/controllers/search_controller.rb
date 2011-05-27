class SearchController < FrontEndController

  helper :topics, :videos, :video_segments, :images, :external_contents

  def search
    
    unless params['q'].nil? || params['q'].empty?

      # Solr fulltext search (sunspot)
      # http://wiki.github.com/outoftime/sunspot/
      # http://wiki.apache.org/solr/DisMaxQParserPlugin (fulltext query syntax)
      # http://outoftime.github.com/sunspot/docs/classes/Sunspot/DSL/StandardQuery.html#M000112 (keyword options)

      begin

        @topic_results = Sunspot.search Topic do
          keywords params['q'], :query_phrase_slop => 1, :minimum_match => 1
          with(:live, true)
          paginate(:page => 1, :per_page => 15)       # TODO: pagination params
        end

        @video_results = Sunspot.search Video do
          keywords params['q'], :query_phrase_slop => 1, :minimum_match => 1
          with(:available, true)
          paginate(:page => 1, :per_page => 10)       # TODO: pagination params
        end

        if !request.accept.present? || !request.accept.match(/application\/json/)

          response = Sunspot.search VideoSegment do
            keywords params['q'], :query_phrase_slop => 1, :minimum_match => 1
            paginate(:page => 1, :per_page => 10)     # TODO: pagination params
          end
          @video_segment_results_by_id = Hash[*response.results.map{|x| [x.id, x]}.flatten]

          @external_results = []
          content_types = ContentType.live

          content_types.each do |type|
            data = {}
            data['type'] = type
            response = Sunspot.search ExternalContent do
              keywords params['q']
              with(:content_type_id, type.id)
              with(:live, true)
              paginate(:page => 1, :per_page => 10)   # TODO: pagination params
            end
            data['results'] = response.results
            ExternalContent.check_for_duplicates data['results']
            @external_results << data
          end

        end

      rescue Exception => exc

        # Solr server connect failure
        logger.error 'Solr server connection failure. Is it running?'
        logger.error exc.message

      end

    end

    data = []

    if request.accept.present? && request.accept.match(/application\/json/)
      # Autocomplete

      if !@topic_results.nil?
        @topic_results.each_hit_with_result do |hit, topic|
          data << {
            'id' => topic.id,
            'url' => @template.parameterized_videos_path(nil, :topic => topic),
            'label' => "Topic: #{topic.name}",
            'description' => strip_xml_tags(topic.description)
          }
        end
      end

      if !@video_results.nil?
        @video_results.each_hit_with_result do |hit, video|
          data << {
            'id' => video.permalink,
            'url' => @template.video_path(video.permalink),
            'label' => "Video: #{video.name}",
            'description' => strip_xml_tags(video.description)
          }
        end
      end

      result = {
        :status => 'success',
        :data => data
      }

      respond_to do |format|
        format.json {
          render :json => result
        }
      end
      return
    end

    @page_title += " - Search Results"

  end

end
