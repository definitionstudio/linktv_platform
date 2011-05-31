Link TV Platform
================

Link TV Platform is a Rails Engine for Ruby on Rails 2.3. 
The platform provides a framework for creating rich video sites, 
integrating Semantic Web technologies and content discovery services.


Features
--------
* Flexible video support
	* Manual video creation or import from MRSS
	* Streaming via Amazon CloudFront, progressive fallback
	* YouTube video support
	* HTML5 video playback for non-Flash environments
* Content analysis & curation
	* Distinct video segments/chapters
	* Auto-suggested topics via video transcript analysis
	* Topic association relevance weighting
* Semantic Web features
	* Linked Data URIs for topics and videos
	* Contextual RDFa markup
	* Topic owl:sameAs links to Freebase and DBpedia
	* RDF/XML endpoints
* Related content discovery
	* Articles
	* Videos
	* Actions
* Search & API
	* Fulltext search powered by Apache Solr
	* Available JSON/XML API


Dependencies
------------
* Rails 2.3 (>= 2.3.8)
* MySQL
* Java 1.5+ (for Solr)
* [Amazon S3](http://aws.amazon.com/s3/) account for CDN-hosted videos
* [Amazon CloudFront](http://aws.amazon.com/cloudfront/) for streaming video
* Plugins
	* [ActiveScaffold](https://github.com/activescaffold/active_scaffold)
	* [ActiveScaffoldSortable](https://github.com/activescaffold/active_scaffold_sortable)
	* [ActsAsList](https://github.com/rails/acts_as_list)
	* [RailsXss](https://github.com/rails/rails_xss)
	* [render_component](https://github.com/ewildgoose/render_component)
* See environment.rb for gem dependencies


Getting Started
---------------
Install the plugin into an existing or newly-created Rails application (requires git).

	script/plugin install git://github.com/definitionstudio/linktv_platform.git
	
Edit your application's config/environment.rb file to include the plugin initializers.

	require "#{RAILS_ROOT}/vendor/plugins/linktv_platform/config/environment.rb"
	Rails::Initializer.run do |config|
		Linktv::Platform::initializer config

Set required variables in config/environments/{environment}.rb (see notes in plugin environment.rb).

* DEVELOPMENT_MODE
* PRODUCTION_MODE

Update application_controller.rb.

	class ApplicationController < ActionController::Base
		include Linktv::Platform::PlatformController

Update your application's config/routes.rb file to include support for "pages" module (just before the last 'end' statement).

	# Lowest priority fall-through route is for site-defined matches to Page records
	# Note: this will catch everything, so 404 handler is within
	map.connect '*path', :controller => 'pages', :action => 'show', :conditions => {:method => :get}

Install required gems.

	$ (sudo) rake gems:install

Install required plugins.

	$ script/plugin install git://github.com/rails/rails_xss.git
	$ script/plugin install git://github.com/rails/acts_as_list.git
	$ script/plugin install git://github.com/activescaffold/active_scaffold.git
	$ script/plugin install git://github.com/activescaffold/active_scaffold_sortable.git
	$ script/plugin install git://github.com/ewildgoose/render_component.git -r rails-2.3

Initialize delayed_job.

	$ script/generate delayed_job
	
Initialize Sunspot/Solr.

	$ script/generate sunspot

Include Sunspot tasks in your application's _Rakefile_.

	require 'sunspot/rails/tasks'

Initialize Link TV Platform: create media directories, symlink assets.

	$ rake linktv_platform:init
	
Create a database, if necessary. Edit your application's config/database.yml file (see database.example.yml).

	development:
	  adapter: mysql
	  database: linktv_platform_development
	  encoding: utf8
	  username: dbDevUser
	  password: dbDevPass

Run database migrations and seed default data.

	$ rake db:migrate
	$ rake linktv_platform:db:seed:all
	
Edit the application configuration, including API keys, in config/application.yml. 
See the [Configuration](https://github.com/definitionstudio/linktv_platform/wiki/Configuration)
page in the wiki for details.

Start Sunspot/Solr. See the [Sunspot Wiki](https://github.com/outoftime/sunspot/wiki) for more info on running Solr in production.

	$ RAILS_ENV={environment} rake sunspot:solr:start
	
Build Solr search index.

	$ RAILS_ENV={environment} rake linktv_platform:sunspot:reindex
	
Start delayed_job background process.

	$ RAILS_ENV=#{rails_env} script/delayed_job start
	
Start the server (using Mongrel, [Passenger](http://www.modrails.com/), etc.). Be sure to remove the default public/index.html file.


### FlowPlayer

[FlowPlayer](http://flowplayer.org), a GPL-licensed Flash video player, is used in the video admin modules. 
The FlowPlayer package is not included with this distribution, due to GPL restrictions. Links to externally-hosted 
resources are provided in the default configuration.

It is highly recommended that you replace these external links with a local installation of FlowPlayer. 
The example below shows an excerpt from the application.yml configuration file, with FlowPlayer installed locally.

	all:
	  video:
	    admin_player:
	      flowplayer_swf: /assets/flowplayer/flowplayer-3.2.7.swf
	      flowplayer_js: /assets/flowplayer/flowplayer-3.2.6.min.js
	      flowplayer_rtmp: /assets/flowplayer/flowplayer.rtmp-3.2.3.swf


### Authorization

Authentication and authorization services are not enabled by default. The administration modules may be secured using HTTP authentication, 
or via the included Authorization module (based on [AuthLogic](https://github.com/binarylogic/authlogic)).
Of course, you are free to provide your own auth system, as well.

See the [Authorization](https://github.com/definitionstudio/linktv_platform/wiki/Authorization) wiki page for details.


### Optional Installs

#### Exception Logger

<http://github.com/defunkt/exception_logger>

#### VideoJS

[VideoJS](http://videojs.com) enhances HTML5 video with improved cross-browser compatibility and UI skinning. 
Download and install VideoJS into your application's public directory (public/video-js, in this example). 
Include the JavaScript and CSS file in player partial (haml):

	- content_for :head do
	  = stylesheet_link_tag "/video-js/video-js.css"
	  = javascript_include_tag "/video-js/video.js"


Notes
-----
* The platform is tested with specific gem and/or plugin versions as specified
  in the configuration. Use of different versions may cause difficulties.


Third-party APIs
----------------
Link TV Platform leverages APIs from the following providers. 
See the [API Providers](https://github.com/definitionstudio/linktv_platform/wiki/API-Providers)
page for API key and attribution requirements.

* [Zemanta](http://www.zemanta.com)
* [Daylife](http://www.daylife.com)
* [Truveo](http://www.truveo.com)
* [Social Actions](http://www.socialactions.com)
* [Freebase](http://www.freebase.com)
* [DBpedia](http://www.dbpedia.org)


Acknowledgements
----------------
Developed by [Definition LLC](http://www.definitionstudio.com)

* Rob DiCiuccio ([robdiciuccio](https://github.com/robdiciuccio))
* Doug Puchalski ([fullware](https://github.com/fullware))
* Evan Rusackas ([rusackas](https://github.com/rusackas))

Produced by [Link Media, Inc.](http://www.linktv.org)

TinyMCE, an LGPL-licensed project, is bundled with this distribution.
Source code available at <http://tinymce.moxiecode.com>.

Administration theme by [web-app-theme](https://github.com/pilu/web-app-theme).

GeoIP lookup service provided by [YQL](http://developer.yahoo.com/yql/).


License
-------
Distributed under the MIT License, copyright (c) 2011 Definition LLC.
A project of Link Media, Inc.