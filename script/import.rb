#! /usr/bin/env ruby

require 'gtfs/base'
require 'gtfs/rennes'
require 'gtfs/stlo'

Importers = { 
  :rennes => Gtfs::Rennes,
  :stlo => Gtfs::StLo 
}

ARGV.each do |cityname|
  citysym = cityname.to_sym
  if Importers.has_key? citysym
    importer = Importers[citysym].new
    importer.run
  end
end
