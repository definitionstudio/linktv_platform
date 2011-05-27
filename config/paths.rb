LINKTV_PLATFORM_ROOT = File.expand_path(File.join File.dirname(__FILE__), '..')
LINKTV_PLATFORM_ASSETS_PATH = '/assets/linktv_platform'
LINKTV_PLATFORM_ASSETS_ROOT = File.join RAILS_ROOT, '/public/assets/linktv_platform'

IMAGE_WORK_ROOT = "#{RAILS_ROOT}/image_work"
IMAGE_CACHE_PATH = "/images/image_cache"
IMAGE_CACHE_ROOT = "#{RAILS_ROOT}/public#{IMAGE_CACHE_PATH}"

# Location in which to store any local media, including downloaded video files and images, as necessary
PRIVATE_MEDIA_ROOT = "#{RAILS_ROOT}/media/#{RAILS_ENV}" unless defined? PRIVATE_MEDIA_ROOT
PRIVATE_IMAGES_ROOT = "#{PRIVATE_MEDIA_ROOT}/images"
