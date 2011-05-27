#
# Set up mappings from XML for the parser.
#
# http://video.search.yahoo.com/mrss
# http://gist.github.com/47938
#

require 'mrss/channel.rb'
require 'feedzirra'
require 'feedzirra/feed_utilities'

module Mrss

	#
	# Class for mapping feed attributes
	#
	class Mrss
		include SAXMachine
		include Feedzirra::FeedUtilities

		elements :channel, :as => :channels, :class => Channel

		attr_accessor :feed_url

		def self.able_to_parse?(xml) #:nodoc:
			xml =~ /\<rss|\<rdf/
		end

	end
	
end
