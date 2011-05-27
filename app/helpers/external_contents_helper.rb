module ExternalContentsHelper

  def external_content_thumbnail_html external_content, args = {}
    args = args.merge({
        :class => 'external-content-thumbnail',
        :alt => external_content.nil? ? nil : external_content.name,
        :width => args[:width],
        :height => args[:height],
        :rw => 1,
        :crop => :center})
    if args[:dynamic] || nil
      dynamic_thumbnail_html(external_content.nil? ? nil : external_content.thumbnail, args)
    else
      thumbnail_html(external_content.nil? ? nil : external_content.thumbnail, args)
    end
    
  end
  safe_helper :external_content_thumbnail_html

  def external_content_attribution content, args = {}
    attr = content.attribution
    return '' if attr.nil? || attr.empty?
    class_attr = args[:class].nil? ? "" : " class=\"#{args[:class]}\""
    rel_attr = args[:rel].nil? ? "" : " rel=\"#{args[:rel]}\""
    property_attr = args[:property].nil? ? "" : " property=\"#{args[:property]}\""
    "<a href=\"http://#{attr[:url]}\" target=\"_blank\" #{class_attr}#{rel_attr}#{property_attr}>#{attr[:name]}</a>"
  end
  safe_helper :external_content_attribution
  
end
