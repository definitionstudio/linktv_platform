# Cache rake tasks

namespace :cache do

  namespace :reset do

    desc "Remove cached imaged files"
    task :images => :environment do
      FileUtils::rm_f Dir.glob("#{IMAGE_CACHE_ROOT}/*")
    end

    desc "Remove locally stored media"
    task :media => :environment do
      FileUtils::rm_rf Dir.glob("#{PRIVATE_MEDIA_ROOT}/*/*")
    end

  end
end
