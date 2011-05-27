module Admin::TopicsHelper

  def topic_entity_identifiers_column record
    "<ul>" +
      record.entity_identifiers.collect{|e| "<li><a target=\"_blank\" href=\"" +  e.uri + "\">#{e.entity_db.name}: #{e.identifier}</a></li>" }.join +
    "</ul>".html_safe
  end
  safe_helper :topic_entity_identifiers_column
end
