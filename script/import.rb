#! /usr/bin/env ruby

require 'csv'
require 'pp'


def mlog msg
  puts Time.now.to_s(:db) + " " + msg
end
    

legacy = {}

all_stops = {}

mlog "loading stops"
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

legacy[:line] = {}
mlog "loading routes"
CSV.foreach( File.join( Rails.root, "/tmp/routes.txt" ),
             :headers => true,
             :header_converters => :symbol,
             :encoding => 'UTF-8' ) do |rawline|
  line = rawline.to_hash
  new_line = Line.create({ :src_id => line[:route_id],
                           :short_name => line[:route_short_name],
                           :long_name => line[:route_long_name],
                           :bgcolor => line[:route_color],
                           :fgcolor => line[:route_text_color] })
  legacy[:line][line[:route_id]] = new_line.id
end

calendar = {}
mlog "loading calendar"
CSV.foreach( File.join( Rails.root, "/tmp/calendar.txt" ),
             :headers => true,
             :header_converters => :symbol,
             :encoding => 'UTF-8' ) do |line|
  cal = line.to_hash
  id = cal[:service_id]
  calendar[id] = 0
  cal.keys.grep(/day$/) do|k|
    if cal[k] == "1"
      calendar[id] |= Calendar.const_get( k.upcase )
    end
  end
end

legacy[:trip] = {}
mlog "loading trips"
CSV.foreach( File.join( Rails.root, "/tmp/trips.txt" ),
             :headers => true,
             :header_converters => :symbol,
             :encoding => 'UTF-8' ) do |rawline|
  line = rawline.to_hash
  trip = Trip.create({ :src_id => line[:trip_id],
                       :calendar => calendar[line[:service_id]],
                       :src_route_id => line[:route_id],
                       :headsign => line[:trip_headsign],
                       :block_id => line[:block_id] })
  legacy[:trip][line[:trip_id]] = {  :line => line[:route_id], :calendar => calendar[line[:service_id]] }
end

def average array
  array.inject{ |sum, el| sum + el }.to_f / array.size
end
    

legacy[:stops] = {}
mlog "storing stops"
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
    legacy[:stops][stop[:stop_id]] = new_stop.id
  end
end

mlog "loading stop_times"
CSV.foreach( File.join( Rails.root, "/tmp/stop_times.txt" ),
             :headers => true,
             :header_converters => :symbol,
             :encoding => 'UTF-8' ) do |rawline|
  line = rawline.to_hash
  if ! legacy[:trip].has_key?(line[:trip_id])
#    puts "Missing trip #{line[:trip_id]}"
    next
  end
  StopTime.create({ :stop_id => legacy[:stops][line[:stop_id]],
                    :line_id => legacy[:trip][line[:trip_id]][:line],
                    :calendar => legacy[:trip][line[:trip_id]][:calendar],
                    :arrival => line[:arrival_time].split(':').inject(0) { |m,v| m = m * 60 + v.to_i },
                    :departure => line[:departure_time].split(':').inject(0) { |m,v| m = m * 60 + v.to_i }
                  })
end
mlog "The end"
