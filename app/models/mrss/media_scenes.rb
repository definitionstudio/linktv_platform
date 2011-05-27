module Mrss

  require "mrss/media_scene.rb"

	class MediaScenes
		include SAXMachine

    elements :'media:scene', :as => :media_scene, :class => MediaScene
	end

end
