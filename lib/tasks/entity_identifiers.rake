namespace :entity_identifiers do

  desc "Update entity identifier data/descriptions."
  task :refresh => :environment do
    puts ":entity_identifiers:refresh begin"
    puts EntityIdentifier.refresh
    puts ":entity_identifiers:refresh end"
  end
  
end

