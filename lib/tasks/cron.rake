# in crontab:
# cd /path/to/rails/app && rake RAILS_ENV=production cron:hourly

namespace :cron do

  desc "Run hourly housekeeping tasks."
  task :hourly => [:environment] do
    puts ":cron:hourly begin"
    Rake::Task["entity_identifiers:refresh"].invoke
    puts ":cron:hourly end"
  end

  desc "Run daily housekeeping tasks."
  task :daily => [:environment] do
    puts ":cron:daily begin"
    GeoIpCache.cleanup
    puts ":cron:daily end"
  end

end

