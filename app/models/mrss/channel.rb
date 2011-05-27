require 'mrss/item.rb'

module Mrss
	#
	# Class for mapping feed attributes
	#
	class Channel
		include SAXMachine

		element :title
		element :description
		element :link
		element :language

		elements :item, :as => :items, :class => Item

	end

end
