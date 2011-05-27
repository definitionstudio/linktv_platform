# Based on http://gist.github.com/99030

namespace :db do
  namespace :mysql do

    desc "Export the database"
    task :export, :env, :pathname do |t, args|

      args.with_defaults(:env => "production", :pathname => nil)
      args = args.to_hash

      config = YAML.load(IO.read("config/database.yml"))
      unless config[args[:env]].present?
        raise "Environment \"#{args[:env]}\" not present in config/database.yml"
      end
      db_config = config[args[:env]]

      unless db_config["adapter"] == "mysql"
        raise "This task works only on mysql"
      end
      db_config["host"] ||= "localhost"

      if args[:pathname].nil? || args[:pathname].empty?
        args[:pathname] = "#{RAILS_ROOT}/db/backups/#{args[:env]}_#{Time.now.strftime("%Y%m%d%H%M%S")}.sql.gz"
      end
      
      puts "Exporting #{args[:env]} database to #{args[:pathname]}"

      gzip = args[:pathname] =~ /\.gz$/ ? "| gzip -c" : ""

      cmd = <<-CMD
        mysqldump -h #{db_config["host"]} -u #{db_config["username"]} \
          -p#{db_config["password"]} #{db_config["database"]} #{gzip} > #{args[:pathname]}
      CMD

      puts cmd
      STDOUT.flush
      `#{cmd}`
      puts "done."

    end

    desc "Import the database"
    task :import, :env, :pathname do |t, args|

      args.with_defaults(:env => "production", :pathname => nil)
      args = args.to_hash

      unless args[:pathname].present?
        raise "Source pathname must be specified."
      end

      unless args[:pathname].present? && File.exist?(args[:pathname])
        raise "Source pathname \"#{args[:pathname]}\" does not exist."
      end

      config = YAML.load(IO.read("config/database.yml"))
      unless config[args[:env]].present?
        raise "Environment \"#{args[:env]}\" not present in config/database.yml"
      end
      db_config = config[args[:env]]

      unless db_config["adapter"] == "mysql"
        raise "This task works only on mysql"
      end
      db_config["host"] ||= "localhost"

      puts "Importing #{args[:pathname]} to #{args[:env]} database"

      # Use a named pipe since mysql requires a file for input
      pipe_path = "/tmp/pipe.#{Time.now.to_i}"
      gzip = args[:pathname] =~ /\.gz$/ ? "| gunzip -c" : ""


      cmd = <<-CMD
        mkfifo #{pipe_path} &&
        (mysql -h #{db_config["host"]} -u #{db_config["username"]} \
            -p#{db_config["password"]} #{db_config["database"]} < #{pipe_path} &) &&
        cat #{args[:pathname]} #{gzip} > #{pipe_path} &&
        rm -f #{pipe_path}
      CMD

      puts cmd
      STDOUT.flush
      `#{cmd}`

      puts "done."
    end

    # Usage:
    # rake db:mysql:clone_db[development,production]
    # Note no spaces or quotes within parameters
    desc "Clone the source database to the target"
    task :clone, :source, :target do |t, args|

      args.with_defaults(:source => "production", :target => "staging")

      # Old version, using intermediate file
#      pathname = "/tmp/db_mysql_clone.#{Time.now.to_i}.sql"
#      Rake::Task["db:mysql:export"].invoke args[:source], pathname
#      Rake::Task["db:mysql:import"].invoke args[:target], pathname
#      File.delete pathname

      config = YAML.load(IO.read("config/database.yml"))

      unless config[args[:source]].present?
        raise "Source environment \"#{args[:source]}\" not present in config/database.yml"
      end
      db_source_config = config[args[:source]]

      unless db_source_config["adapter"] == "mysql"
        raise "This task works only on mysql"
      end
      db_source_config["host"] ||= "localhost"

      unless config[args[:target]].present?
        raise "Target environment \"#{args[:target]}\" not present in config/database.yml"
      end

      db_target_config = config[args[:target]]

      unless db_target_config["adapter"] == "mysql"
        raise "This task works only on mysql"
      end
      db_target_config["host"] ||= "localhost"

      pipe_path = "/tmp/pipe.#{Time.now.to_i}"

      cmd = <<-CMD
        mkfifo #{pipe_path} &&
        (mysql -h #{db_target_config["host"]} -u #{db_target_config["username"]} \
            -p#{db_target_config["password"]} #{db_target_config["database"]} < #{pipe_path} &) &&
        mysqldump -h #{db_source_config["host"]} -u #{db_source_config["username"]} \
          -p#{db_source_config["password"]} #{db_source_config["database"]} > #{pipe_path} &&
        rm -f #{pipe_path}
      CMD
      
      puts cmd
      STDOUT.flush
      `#{cmd}`

      puts "done."
      
    end
  end
end
