# Linktv::Platform
require File.join File.dirname(__FILE__), '/paths.rb'

# Appication should set these as appropriate in config/environments/{environment}.rb
DEVELOPMENT_MODE = false
PRODUCTION_MODE = false

# init global config
APP_CONFIG = nil

module Linktv
  module Platform
    
    # Should be required in app's environment.rb:
    #
    # require "#{RAILS_ROOT}/vendor/plugins/linktv_platform/config/environment.rb"
    #
    # Rails::Initializer.run do |config|
    #   ...
    #   Linktv::Platform::initializer config
    #   ...
    # end

    def self.initializer config

      config.middleware.use "Thumbnailer"

      config.gem "i18n", :version => '0.4.2'              # user older version to prevent errors w/rails 2.3.8 (may need to uninstall newer gem, if installed)
      config.gem "mysql", :version => '2.8.1'
      config.gem "json", :version => '1.4.6'
      config.gem "haml", :version => '3.1.2'
      config.gem "symbolize", :version => '3.0.1'
      config.gem "permalink_fu", :version => '1.0.0'
      config.gem "will_paginate", :version => '2.3.14'
      config.gem "daemons", :version => '1.0.10'          # daemons gem (v1.0.10) required for delayed_job execution (1.1.0 not compatible)
      config.gem "delayed_job", :version => '2.0.7'
      config.gem "aws-s3", :version => '0.6.2', :lib => "aws/s3"
      config.gem "gd2", :version => '1.1.1'
      config.gem "rio", :version => '0.4.2'
      config.gem "searchlogic", :version => '2.4.25'
      config.gem 'sunspot_rails', :version => '1.2.1'

      # Required for rails_xss plugin
      config.gem "erubis", :version => '2.6.6'

      # RSS/XML handling
      config.gem "nokogiri", :version => '1.5.6'
      config.gem "builder", :version => '= 2.1.2'
      config.gem "feedzirra", :version => '0.0.24'
      config.gem "sax-machine", :version => '0.1.0'

      config.after_initialize do

        # load initializers
        Dir["#{LINKTV_PLATFORM_ROOT}/config/initializers/**/*.rb"].sort.each do |initializer|
          load(initializer)
        end

        require 'extensions/active_record'

        # handle Solr server connect errors (silently)
        require 'sunspot_rails'
        Sunspot.session = Sunspot::SessionProxy::SilentFailSessionProxy.new(Sunspot.session)

        require 'extensions/delayed_job'

      end
    end
  end
end
