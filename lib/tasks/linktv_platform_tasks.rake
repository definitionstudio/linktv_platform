require File.join File.dirname(__FILE__), "..", "..", "config", "paths.rb"

namespace :linktv_platform do

  desc "Initialize the application to work with the LinkTV Platform plugin"
  task :init do
    # create private media store
    system "mkdir -p #{RAILS_ROOT}/media"

    # Symlink to plugin-related assets
    system "mkdir -p #{RAILS_ROOT}/public/assets"
    system "rm -f #{RAILS_ROOT}/public/assets/linktv_platform"
    system "ln -s #{LINKTV_PLATFORM_ROOT}/assets/linktv_platform #{RAILS_ROOT}/public/assets/linktv_platform"

    # Copy db migrations
    #system "rm -f #{RAILS_ROOT}/db/migrate/??????????????_linktv_platform_*.rb"
    Dir.chdir("#{LINKTV_PLATFORM_ROOT}/db/migrate") do
      Dir["*.rb"].each do |filename|
        system "cp #{LINKTV_PLATFORM_ROOT}/db/migrate/#{filename} #{RAILS_ROOT}/db/migrate"
      end
    end

  end

  # requires annotate gem
  namespace :annotate do
    desc "Annotate the plugin models"
    task :models do
      system "annotate -e tests -e fixtures --model-dir vendor/plugins/linktv_platform/app/models"
    end

    desc "Annotate routes"
    task :routes do
      system "annotate -e tests -e fixtures -e models -r"
    end
  end

  namespace :images do

    desc "Backup all image media"
    task :backup do
      system "cd #{PRIVATE_IMAGES_ROOT}/..; tar cf - images | gzip -c > images.#{Date.today.to_s}.tar.gz"
    end

    namespace :cleanup do

      # TODO: update Image.cleanup to delete orphaned files explicitly,
      # not traverse file system & query for each file
      
      desc "Cleanup ophan images and image media. Recommend image backup before running this."
      task :orphans => :environment do
        Image.cleanup
      end
      
      desc "Cleanup image cache. Can safely be run any time."
      task :image_cache do
        FileUtils.rm_rf Dir[File.join IMAGE_CACHE_ROOT, "*"]
      end
      
    end
    
  end

  # Seed the database with standard configuration data.
  namespace :db do
    namespace :seed do
      desc "Seed all"
      task :all => :environment do
        Rake::Task['linktv_platform:db:seed:regions'].execute
        Rake::Task['linktv_platform:db:seed:content_types'].execute
        Rake::Task['linktv_platform:db:seed:footer_links'].execute
        Rake::Task['linktv_platform:db:seed:entity_dbs'].execute
        Rake::Task['linktv_platform:db:seed:semantic_apis'].execute
        Rake::Task['linktv_platform:db:seed:roles'].execute
        Rake::Task['linktv_platform:db:seed:countries'].execute
        Rake::Task['linktv_platform:db:seed:playlists'].execute
      end

      desc "Seed regions, based on world bank regions"
      task :regions => :environment do
        # World bank regions
        ActiveRecord::Base.connection.execute("TRUNCATE regions")
        Region.create! :name => "East Asia & Pacific", :code => "EAP"
        Region.create! :name => "Europe & Central Asia", :code => "ECA"
        Region.create! :name => "Latin America & Caribbean", :code => "LCR"
        Region.create! :name => "Middle East & North Africa", :code => "MNA"
        Region.create! :name => "North America", :code => "NAC"
        Region.create! :name => "South Asia", :code => "SAR"
        Region.create! :name => "Sub-Saharan Africa", :code => "AFR"
      end

      desc "Seed content types"
      task :content_types => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE content_types")
        ContentType.create!({:name => 'Related Videos', :item_type => 'video', :display_order => 1})
        ContentType.create!({:name => 'Related Articles', :item_type => 'article', :display_order => 2})
        ContentType.create!({:name => 'Social Actions', :item_type => 'action', :display_order => 3})
      end

      desc "Seed footer links and associated pages"
      task :footer_links => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE links")
        ActiveRecord::Base.connection.execute("TRUNCATE pages")
        # Footer links and associated pages
        [
          ['/about',       'About'],
          ['/terms',       'Terms of Service']
        ].each do |footer_page|

          page = Page.create! :name => footer_page[1], :path => footer_page[0],
            :content => "This is the sample seeded page content for #{footer_page[0]} (#{footer_page[1]})", :active => true
          Link.create! :group => 'footer', :page => page, :name => page.name, :active => true
        end
      end

      desc "Seed Entity DB's"
      task :entity_dbs => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE entity_dbs")
        FreebaseApi.create!({
          :name => "Freebase",
          :url => "http://www.freebase.com",
          :icon_css_class => 'icon-freebase',
          :identifier_regex => '^http://([^\./]+\.)?freebase.com/',
          :active => true})
        DbpediaApi.create!({
          :name => "DBpedia",
          :url => "http://www.dbpedia.org",
          :icon_css_class => 'icon-dbpedia',
          :identifier_regex => '^http://([^\./]+\.)?dbpedia.org/resource/',
          :active => true})
      end

      desc "Seed Semantic API's"
      task :semantic_apis => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE semantic_apis")

        zemanta = ZemantaApi.create!({
            :name => "Zemanta",
            :url => "http://api.zemanta.com/services/rest/0.0/",
            :query_params => nil,
            :quota_config => nil,
            :active => true,
            :lifetime => nil})

        social_actions = SocialActionsApi.create!({
            :name => "Social Actions",
            :url => "http://search.socialactions.com/actions.json",
            :query_params => nil,
            :quota_config => nil,
            :active => true,
            :lifetime => nil})

        daylife = DaylifeApi.create!({
            :name => "Daylife",
            :url => "http://freeapi.daylife.com/jsonrest/publicapi/4.8/search_getRelatedArticles",
            :query_params => nil,
            :quota_config => nil,
            :active => true,
            :lifetime => nil})

        truveo = TruveoApi.create!({
            :name => "Truveo",
            :url => "http://xml.truveo.com/apiv3",
            :query_params => nil,
            :quota_config => nil,
            :active => true,
            :lifetime => nil})

        ct_videos = ContentType.find_by_name('Related Videos')
        ct_articles = ContentType.find_by_name('Related Articles')
        ct_actions = ContentType.find_by_name('Social Actions')

        ContentTypeSemanticApi.create!({:semantic_api_id => truveo.id, :content_type_id => ct_videos.id})
        ContentTypeSemanticApi.create!({:semantic_api_id => zemanta.id, :content_type_id => ct_articles.id})
        ContentTypeSemanticApi.create!({:semantic_api_id => daylife.id, :content_type_id => ct_articles.id})
        ContentTypeSemanticApi.create!({:semantic_api_id => social_actions.id, :content_type_id => ct_actions.id})
      end

      desc "Seed default roles"
      task :roles => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE roles")
        
        Role.create! :name => 'admin', :active => true
        Role.create! :name => 'super_admin', :active => true
        Role.create! :name => 'user_admin', :active => true
      end

      desc "Seed default playlists"
      task :playlists => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE playlists")

        Playlist.create! :name => "Featured Videos"
        Playlist.create! :name => "Featured Topics"
      end

      desc "Seed default users (not run with :all)"
      task :users => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE users")

        role_admin = Role.find_by_name 'admin'
        role_super_admin = Role.find_by_name 'super_admin'

        user = User.new({
          :display_name => 'Administrator'})
        user.login = 'admin'
        user.password = 'admin'
        user.password_confirmation = 'admin'
        user.email = 'admin@my.host.com'
        user.active = true
        user.save!
        role_admin.users << user
        role_super_admin.users << user
      end

      require 'active_record/fixtures'
      desc "Seed the countries table, using tasks/data/countries.yml"
      task :countries => :environment do
        ActiveRecord::Base.connection.execute("TRUNCATE countries")

        directory = File.join(File.dirname(__FILE__), "data")
        Fixtures.create_fixtures(directory, "countries")
      end
    end
  end

  namespace :sunspot do

    desc "Reindex all necessary models. Use this task rather than the sunspot:reindex since models are not defined in app/models."
    task :reindex do
      Rake::Task['sunspot:reindex'].invoke(nil, "Video+VideoSegment+Topic+ExternalContent")
    end

  end

end
