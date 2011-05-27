# Methods added to this helper will be available to all templates in the application.
module PlatformHelper

  def footer_links
    @footer_links ||= Link.scoped_by_group('footer').live.include_page.ordered
  end

  def icon css_class = nil, args = {}
    # Note: using CSS sprites. Icon is selected by the css_class
    "<img class=\"icon #{css_class}\"" +
      (args[:url].present? ? "style=\"background-image: url(#{args[:url]})\"" : '') +
      (args[:title].present? ? " title=\"#{args[:title]}\"" : '') +
      " src=\"#{LINKTV_PLATFORM_ASSETS_PATH}/images/pixel.png\" alt=\"\"/>"
  end
  safe_helper :icon

  # Return a unique index each time the method is called.
  # Prefix is time (in seconds) of the request
  # Useful to ensure that nested form attributes are unique even if form fields are generated separately
  def unique_index
    @unique_index_time ||= (Time::now.to_f * 1000000).to_i
    @unique_index ||= -1
    @unique_index += 1
    @unique_index_time.to_s + '-' + @unique_index.to_s
  end

  def blank_image_tag
    "<image/>"
  end

  def sanitize_html str, args = {}
    return nil unless str.present? && str.is_a?(String)
    tags = %w(a acronym b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p)
    sanitize str, :tags => tags, :attributes => %w(href title)

    if args[:add_links].present?
      # TODO wrap non-HTML links into anchor tags
    end

    str
  end

  def loading_indicator args = {}
    args[:class] ||= []
    args[:class] = args[:class].split(' ') unless args[:class].is_a? Array
    css_classes = ['ajax-loader'] + args[:class] + (args[:inline] ? ['inline'] : [])
    "<span class=\"#{css_classes.join(' ')}\"><img src=\"#{LINKTV_PLATFORM_ASSETS_PATH}/images/pixel.png\"/></span>"
  end
  safe_helper :loading_indicator

  def loading_html args = {}
    args[:class] ||= []
    args[:class] = args[:class].split(' ') unless args[:class].is_a? Array
    css_classes = ['ajax-loader'] + args[:class] + (args[:inline] ? ['inline'] : [])
    "<span class=\"#{css_classes.join(' ')}\"><span class=\"ajax-loader-text\">Loading...</span></span>"
  end
  safe_helper :loading_html

  def limited_list_show_more_html
    render_to_string :partial => '/limited_list_show_more'
  end
  safe_helper :limited_list_show_more_html

end
