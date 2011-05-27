namespace :video_sources do

  desc "Update all video source feeds."
  task :update_feeds => :environment do
    puts ":video_sources:update_feeds begin"
    puts VideoSource.update_feeds
    puts ":video_sources:update_feeds end"
  end
  
end

