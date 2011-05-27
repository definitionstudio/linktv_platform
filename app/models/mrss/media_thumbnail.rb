module Mrss
	class MediaThumbnail
		include SAXMachine
		element ':media:thumbnail', :value => :url, :as => :media_thumbnail_url
	end
end
