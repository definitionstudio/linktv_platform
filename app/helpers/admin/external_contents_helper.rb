module Admin::ExternalContentsHelper

  def content_object_html_attrs object

    attrs = {:class => ["object-external-content"], :data => {:identifier => object.identifier}}

    if object.deleted
      attrs[:class] << 'state-deleted'
      attrs[:data][:deleted] = 1
    else
      attrs[:data][:deleted] = 0
    end

    if object.sticky
      attrs[:class] << 'state-sticky'
      attrs[:data][:sticky] = 1
    else
      attrs[:data][:sticky] = 0
    end

    if object.manual
      attrs[:class] << 'state-manual'
      attrs[:data][:manual] = 1
    else
      attrs[:data][:manual] = 0
    end

    if object.static || object.deleted || object.sticky || object.manual
      attrs[:class] << 'state-static'
      attrs[:class] << 'original-state-static'
      attrs[:data][:static] = 1
    else
      attrs[:data][:static] = 0
    end

    if object.filtered?
      attrs[:class] << 'state-filtered'

      if object.is_duplicate
        attrs[:class] << 'state-duplicate'
      end

      if object.has_low_score
        attrs[:class] << 'state-has-low-score'
      end

      if object.is_filtered_by_topic
        attrs[:class] << 'state-filtered-by-topic'
      end
    end

    attrs[:class] = attrs[:class].join(' ')

    attrs
  end

  def content_object_info_attrs object
    return nil unless object.filtered?

    attrs = {:class => ["external-content-info"], :title => ''}


    if object.is_duplicate
      attrs[:title] << 'This item is a duplicate. '
    end

    if object.has_low_score
      attrs[:title] << 'This item has a low score. '
    end

    if object.is_filtered_by_topic
      attrs[:title] << "This item's title contains a filtered topic term. "
    end

    attrs[:title] << 'It will be omitted in results, unless made sticky.'

    attrs[:class] = attrs[:class].join(' ')
    attrs
  end

end
