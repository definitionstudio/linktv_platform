module Mrss

	class MediaScene
		include SAXMachine

    element :sceneTitle
    element :sceneDescription
    element :sceneStartTime
    element :sceneEndTime
	end
end
