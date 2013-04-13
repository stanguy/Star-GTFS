require 'gtfs/base'
require 'gtfs/rennes'
require 'gtfs/stlo'
require 'gtfs/bordeaux'

namespace :stargtfs do

  POST_IMPORT_TASKS = %w{ sunspot:reindex sitemap:refresh stargtfs:maptimize_export stargtfs:cache_clear }

  desc "Import a number of agencies"
  task :import, [:agencies] => :environment do|t,args|
    args.with_defaults( :agencies => 'rennes:bordeaux:saintlo' )
    Importers = { 
      :rennes => Gtfs::Rennes,
      :saintlo => Gtfs::StLo,
      :bordeaux => Gtfs::Bordeaux 
    }
    
    args[:agencies].split(/:/).each do |cityname|
      citysym = cityname.to_sym
      if Importers.has_key? citysym
        current_scheme = cityname + "_" + Time.now.to_i.to_s
        Apartment::Database.create( current_scheme )
        Apartment::Database.switch( current_scheme )
        importer = Importers[citysym].new
        importer.run
        if ActiveRecord::Base.connection.schema_exists? cityname
          ActiveRecord::Base.connection.execute "DROP SCHEMA #{cityname} CASCADE"
        end
        ActiveRecord::Base.connection.execute "ALTER SCHEMA #{current_scheme} RENAME TO #{cityname}"
      else
        print "No importer for #{citysym}"
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
    ActiveRecord::Migration.add_index(:lines, [:agency_id], {:name=>"index_lines_on_agency_id"})
    POST_IMPORT_TASKS.each do |t| 
      Rake::Task[t].invoke
    end
  end

  task :cache_clear => :environment do
    Rails.cache.clear
  end

end
