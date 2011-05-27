module Mrss

  require "mrss/media_content.rb"

	class MediaGroup
		include SAXMachine

		elements :'media:content', :as => :media_contents, :class => MediaContent
		element :'media:thumbnail', :value => :url, :as => :media_thumbnail_url
		element :'media:keywords', :as => :media_keywords
		element :'media:text', :as => :media_text
		element :'media:credit', :as => :media_credit
		element :'media:credit', :value => :role, :as => :media_credit_role
		element :'media:copyright', :as => :media_copyright
    element :'media:scenes', :as => :media_scenes, :class => MediaScenes
	end

end
