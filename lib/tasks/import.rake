require 'gtfs/base'
require 'gtfs/rennes'
require 'gtfs/stlo'

namespace :stargtfs do
  desc "tamere"
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
end
