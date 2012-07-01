require 'gtfs/base'
require 'gtfs/rennes'
require 'gtfs/stlo'

namespace :stargtfs do

  POST_IMPORT_TASKS = %w{ sunspot:reindex sitemap:refresh stargtfs:maptimize_export stargtfs:cache_clear }

  desc "Import a number of agencies"
  task :import, [:agencies] => :environment do|t,args|
    args.with_defaults( :agencies => 'rennes:stlo' )
    Importers = { 
      :rennes => Gtfs::Rennes,
      :stlo => Gtfs::StLo 
    }
    
    args[:agencies].split(/:/).each do |cityname|
      citysym = cityname.to_sym
      if Importers.has_key? citysym
        importer = Importers[citysym].new
        importer.run
      end
    end
  end

  desc "Import default agencies while running"
  task :parallel_import => :environment do
    current_schema = "s" + Time.now.to_i.to_s
    conn = ActiveRecord::Base.connection
    target_schema = conn.current_schema
    if target_schema == "public"
      puts "Wrong schema base"
      next
    end
    if conn.schema_exists? current_schema
      conn.execute "DROP SCHEMA " + current_schema + " CASCADE"
    end
    conn.execute "CREATE SCHEMA " + current_schema
    conn.schema_search_path= current_schema + ",public"
    Rake::Task["db:schema:load"].invoke
    Rake::Task["stargtfs:import"].invoke
    conn.execute "DROP SCHEMA " + target_schema + " CASCADE"
    conn.execute "ALTER SCHEMA " + current_schema + " RENAME TO " + target_schema
    conn.schema_search_path = target_schema + ",public"
    POST_IMPORT_TASKS.each do |t| 
      Rake::Task[t].invoke
    end
  end

  task :cache_clear => :environment do
    Rails.cache.clear
  end

end
