ActionController::Routing::Routes.draw do |map|

  #
  # Front end
  # Note: Defining most used and front-end routes first for speed.
  #

  # May override in application
  map.root :controller => 'home'
  map.home '/', :controller => 'home', :action => 'index'

  map.resources :videos, :only => [:index, :show],
      :member => {:player => :get, :swf => :get, :register_play => :post}

  map.video_sitemap 'video-sitemap.:format', :controller => 'videos', :action => 'sitemap'

  map.resources :video_segments, :only => [:show]
  
	map.resources :topics, :only => [:index],
    :collection => {:autocomplete => :get}

  map.topic 'topics/:identifier.:format', :controller => 'topics', :action => 'show'
  
	map.resources :images, :only => [:show]

  map.search 'search', :controller => 'search', :action => 'search'

  # Thumbnails, both parameterized and a default.
  # Rails will only kick in if the file doesn't exist in the image_cache directory.
  image_formats = /png|jpg/
  map.image_thumbnail 'images/image_cache/:base_dir/:id/thumbnail.:format',
    :controller => 'images', :action => 'thumbnail', :format => image_formats
  map.image_thumbnail 'images/image_cache/:base_dir/:id/thumbnail.:options.:format',
    :controller => 'images', :action => 'thumbnail', :format => image_formats

  # Route to "null" action, this is only used for generating named routes to an existing file
  map.cached_image 'images/image_cache/:filename.:format',
    :controller => 'images', :action => 'null', :format => image_formats

  #
  # API
  #
  
  map.namespace :api do |api|
    api.namespace :v1 do |api_v1|

      api_v1.resources :regions, :only => [:index, :show]
      api_v1.resources :topics, :only => [:index, :show],
        :collection => {:search => :get}
      api_v1.resources :videos, :only => [:index, :show],
        :collection => {:search => :get}

    end
  end

  #
  # Admin
  #

  map.namespace :admin do |admin|
    admin.home "", :controller => "index", :action => "index"
    admin.login "login", :controller => "user_session", :action => "new"
    admin.logout "logout", :controller => "user_session", :action => "destroy"

    admin.new_videos 'new_videos', :controller => "imported_videos", :action => "index", :status => 'new'
    admin.rejected_videos 'rejected_videos', :controller => "imported_videos", :action => "index", :status => 'rejected'

    admin.resource :user, :controller => 'user', :only => [:show, :edit, :update]
    admin.resource :user_session, :controller => "user_session"

    admin.resources :content_sources,
      :active_scaffold => true
    admin.resources :content_types,
      :active_scaffold => true
    admin.resources :countries, :only => [],
      :collection => {:autocomplete => :get},
      :active_scaffold => true
    admin.resources :entity_dbs,
      :member => {:autocomplete => :get},
      :active_scaffold => true
    admin.resources :entity_identifiers,
      :member => {:lookup => :get},
      :collection => {:lookup_by_uri => :get}
    admin.resources :external_contents
    admin.resources :images,
      :active_scaffold => true
    admin.resources :imported_videos,
      :active_scaffold => true
    admin.resources :links,
      :active_scaffold => true
    admin.resources :pages,
      :active_scaffold => true
    admin.resources :playlist_items,
      :active_scaffold => true,
      :active_scaffold_sortable => true
    admin.resources :playlists,
      :active_scaffold => true
    admin.resources :regions,
      :active_scaffold => true
    admin.resources :semantic_apis,
      :active_scaffold => true
    admin.resources :topic_video_segments,
      :active_scaffold => true
    admin.resources :topics,
      :collection => {:matching => :get},
      :member => {:reset_permalink => :post},
      :active_scaffold => true
    admin.resources :users,
      :active_scaffold => true
    admin.resources :videos, :has_many => :video_segments,
      :member => {:add_segment => :post, :undelete => :post},
      :active_scaffold => true
    admin.resources :video_segments,
      :member => {:create_topic => :post, :external_contents => :post, :query_external_contents => :post},
      :collection => {:suggested_topics => :post},
      :active_scaffold => true
    admin.resources :video_sources,
      :member => {:update_feed => :post},
      :active_scaffold => true
    admin.resources :video_files,
      :member => {:download => :post},
      :active_scaffold => true
  end


  # logged_exceptions (optional)
  begin
    require 'logged_exception'
  rescue LoadError
  else
    map.logged_exceptions '/logged_exceptions/:action/:id',
      :controller => 'logged_exceptions', :action => 'index', :id => nil
  end

  #
  # Super admin
  #

  map.namespace :super_admin do |super_admin|
    super_admin.resources :video_files,
      :member => {:download_from_source => :post},
      :active_scaffold => true

    super_admin.resources :video_segments,
      :active_scaffold => true
    
    [
      :countries,
      :entity_identifiers,
      :external_contents,
      :images,
      :imported_videos,
      :roles,
      :topics,
      :video_sources
    ].each do |res|
      super_admin.resources res, :active_scaffold => true
    end
  end

end
