module Api::V1::TopicsHelper

  def topic_api_response_object topic, params = {}
    {
      :id => topic.id,
      :name => topic.name,
      :url => topic_url(topic.permalink, :host => APP_CONFIG[:site][:host]),
      :description => topic.description,
      :entities => topic.entity_identifiers.map {|i| {
        :source => i.entity_db.url,
        :url => i.uri}}
    }
  end

end
