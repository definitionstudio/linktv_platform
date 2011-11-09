module Mrss

  require "mrss/media_group.rb"

  class Item
    include SAXMachine

    element :title
    element :link
    element :guid
    element :guid, :value => :isPermalink, :as => :guid_is_permalink
    element :description
    element :pubDate, :as => :published_at
    element :'media:thumbnail', :value => :url, :as => :media_thumbnail_url
    element :'media:keywords', :as => :media_keywords
    element :'media:text', :as => :media_text
    element :'media:credit', :as => :media_credit
    element :'media:credit', :value => :role, :as => :media_credit_role
    element :'media:copyright', :as => :media_copyright
    element :'media:copyright', :value => :url, :as => :media_copyright_url
    element :'media:license', :as => :media_license
    element :'media:license', :value => :href, :as => :media_license_href
    element :'creativecommons:license', :as => :creativecommons_license
    element :enclosure, :value => :url, :as => :enclosure_url
    element :enclosure, :value => :type, :as => :enclosure_type
    element :enclosure, :value => :length, :as => :enclosure_length
    element :'media:group', :as => :media_group, :class => MediaGroup
    elements :'media:content', :as => :media_contents, :class => MediaContent
    element :'media:scenes', :as => :media_scenes, :class => MediaScenes
  end

end
