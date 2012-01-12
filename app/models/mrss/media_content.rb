module Mrss

  class MediaContent
    include SAXMachine

    element :'media:content', :value => :url, :as => :media_content_url
    element :'media:content', :value => :fileSize, :as => :media_content_filesize
    element :'media:content', :value => :type, :as => :media_content_type
    element :'media:content', :value => :medium, :as => :media_content_medium
    element :'media:content', :value => :isdefault, :as => :media_content_isdefault
    element :'media:content', :value => :expression, :as => :media_content_expression
    element :'media:content', :value => :bitrate, :as => :media_content_bitrate
    element :'media:content', :value => :framerate, :as => :media_content_framerate
    element :'media:content', :value => :samplingrate, :as => :media_content_samplingrate
    element :'media:content', :value => :channels, :as => :media_content_channels
    element :'media:content', :value => :duration, :as => :media_content_duration
    element :'media:content', :value => :height, :as => :media_content_height
    element :'media:content', :value => :width, :as => :media_content_width
    element :'media:content', :value => :lang, :as => :media_content_lang
  end
end
