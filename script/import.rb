#! /usr/bin/env ruby

require 'csv'
require 'pp'

all_stops = {}

CSV.foreach( File.join( Rails.root, "/tmp/stops.txt" ),
             :headers => true,
             :header_converters => :symbol,
             :encoding => 'UTF-8' ) do |line|
  stop = line.to_hash
  name = stop[:stop_name].downcase.gsub( /[ -_\.]/, '' )
  unless all_stops.has_key? name
    all_stops[name] = []
  end
  all_stops[name] << stop
end

all_lines = []
CSV.foreach( File.join( Rails.root, "/tmp/routes.txt" ),
             :headers => true,
             :header_converters => :symbol,
             :encoding => 'UTF-8' ) do |line|
  all_lines << line.to_hash
end

def average array
  array.inject{ |sum, el| sum + el }.to_f / array.size
end
    

all_stops.each do |short_name,stops|
  real_name = ''
  names = stops.collect {|s| s[:stop_name] }
  if names.uniq.length == 1
    real_name = names.first
  else
    counts = names.inject(Hash.new(0)) {|h,i| h[i] += 1; h }
    real_name = counts.keys.sort { |a,b| counts[a] <=> counts[b] }.last
  end
  new_stop = Stop.create({ :stop_name => real_name, 
                           :lat => average( stops.collect{|s| s[:stop_lat] } ),
                           :lon => average( stops.collect{|s| s[:stop_lon] } ) })
  stops.each do |stop|
    new_stop.stop_aliases.create({ :src_id => stop[:stop_id],
                                   :src_code => stop[:stop_code],
                                   :src_name => stop[:stop_name],
                                   :src_lat => stop[:stop_lat],
                                   :src_lon => stop[:stop_lon] })
  end
end

all_lines.each do |line|
  Line.create({ :src_id => line[:route_id],
                :short_name => line[:route_short_name],
                :long_name => line[:route_long_name],
                :bgcolor => line[:route_color],
                :fgcolor => line[:route_text_color] })
end
