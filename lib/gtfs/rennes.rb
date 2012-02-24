# -*- coding: utf-8 -*-

require 'point'
require 'yajl/http_stream'
require 'opendata_api'
require 'gmap_polyline_encoder'


module Gtfs
  class Rennes < Base
    def city
      "Rennes"
    end
    def ads_allowed
      true
    end
    def line_usage line
      return :urban if [ 'Urbaine', 'Inter-quartiers', 'Majeure' ].include? line[:route_desc] 
      return :express if line[:route_desc].match( /^Express/ )
      return :suburban if [ 'Intercommunale', 'Suburbaine' ].include? line[:route_desc]
      :special
    end

    def shorten_long_name line
      basename = line[:route_long_name]
      basename.split( '<>' ).map(&:strip).collect do |destination|
        if m = destination.match( /^([^\/(]*) [\/(]/ )
          m[1]
        else
          destination
        end
      end.join( ' - ' )
    end

    def average array
      array.inject{ |sum, el| sum + el }.to_f / array.size
    end
    
    NB_RECORDS_TO_INSERT = ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::SQLite3Adapter" ? 1 : 1000
    def flush stop_times
      return if stop_times.empty?
      sql = <<SQL
  INSERT INTO stop_times 
    ( stop_id, line_id, trip_id, headsign_id, calendar, arrival, departure, stop_sequence )
  VALUES
SQL
      sql += stop_times.collect do |stoptime|
        "(" + [ stoptime.stop_id, stoptime.line_id, stoptime.trip_id, stoptime.headsign_id, stoptime.calendar, stoptime.arrival, stoptime.departure, stoptime.stop_sequence ].join(",") + ")"
      end.join(",")
      ActiveRecord::Base.connection.execute( sql )
      stop_times.clear
    end



    def initialize
      super
      @steps.insert( @steps.index("stops"), "stops_extensions" )
      @steps.insert( @steps.index("routes"), "routes_extensions" )
      # 
      @legacy = {} #
    end

    def pre_stops_extensions
      @stops_accessible = Hash.new(false)
    end

    handle :stops_extensions do |line|
      @stops_accessible[line[:stop_id]] = line[:stop_accessible].to_i == 1
    end

    handle :agency do |line|
      @agency = Agency.create( :name => line[:agency_name],
                               :url => line[:agency_url],
                               :tz => line[:agency_timezone],
                               :phone => line[:agency_phone],
                               :lang => line[:agency_lang],
                               :city => city,
                               :ads_allowed => ads_allowed )
    end

    def pre_stops
      @all_stops = {}
      @cities = {}
    end

    handle :stops do |line|
      next unless line[:stop_code].match(/^[0-9]+$/)
      name = line[:stop_name].downcase.gsub( /[ -_\.]/, '' )
      unless @all_stops.has_key? name
        @all_stops[name] = []
      end
      @all_stops[name] << line
      if not @stops_accessible.has_key? line[:stop_id]
        puts "missing accessible key for #{line[:stop_id]}"
      end
    end
    
    def post_stops
      valid_stops = {}
      @all_stops.each do |shortname,stops|
        checked_stops = { }
        p = Point.from_lon_lat( stops.first[:stop_lon].to_f, stops.first[:stop_lat].to_f, 4326 )
        checked_stops[p] = [stops.shift]
        stops.each do |stop|
          found = false
          p2 = Point.from_lon_lat( stop[:stop_lon].to_f, stop[:stop_lat].to_f, 4326 )
          checked_stops.each do |p,cs_stops|
            if p.ellipsoidal_distance( p2 ) < 200
              found = true
              cs_stops << stop
              break
            end
          end
          if not found
            checked_stops[p2] = [stop]
          end
        end
        if checked_stops.keys.count > 1
          checked_stops.values.each_with_index do|new_stops,idx|
            valid_stops[ shortname + idx.to_s ] = new_stops
          end
        else
          valid_stops[shortname] = checked_stops.values.first
        end
      end
      @all_stops = valid_stops
      @legacy[:stops] = {}
      @all_new_stops = {}
      # second part
      @all_stops.each do |short_name,stops|
        real_name = ''
        names = stops.collect {|s| s[:stop_name] }
        if names.uniq.length == 1
          real_name = names.first
        else
          counts = names.inject(Hash.new(0)) {|h,i| h[i] += 1; h }
          real_name = counts.keys.sort { |a,b| counts[a] <=> counts[b] }.last
        end
        city_name = stops.first[:stop_desc]
        unless @cities.has_key? city_name
          @cities[city_name] = City.create({ :name => city_name })
        end
        is_accessible = stops.collect {|s| @stops_accessible[s[:stop_id]] }.uniq.count == 1 ? @stops_accessible[stops.first[:stop_id]] : false
        lat = average( stops.collect{|s| s[:stop_lat].to_f } )
        lon = average( stops.collect{|s| s[:stop_lon].to_f } )
        new_stop = Stop.create({ :name => real_name,
                                 :agency_id => @agency.id,
                                 :lat => lat,
                                 :lon => lon,
                                 :geom => Point.from_lon_lat( lon, lat, 4326 ),
                                 :city_id => @cities[city_name].id,
                                 :accessible => is_accessible })
        stops.each do |stop|
          new_stop.stop_aliases.create({ :src_id => stop[:stop_id],
                                         :src_code => stop[:stop_code],
                                         :src_name => stop[:stop_name],
                                         :src_lat => stop[:stop_lat],
                                         :src_lon => stop[:stop_lon],
                                         :description => stop[:stop_desc],
                                         :accessible => @stops_accessible[stop[:stop_id]] })
          @legacy[:stops][stop[:stop_id]] = new_stop.id
        end
        @all_new_stops[new_stop.id] = new_stop
      end
    end
    
    def pre_routes_extensions
      @lines_accessible = Hash.new(false)
    end
    handle :routes_extensions do |line|
      @lines_accessible[line[:route_id]] = line[:route_accessible].to_i == 1
    end

    def pre_routes
      @legacy[:line] = {}
      @lines_stops = {}
      @all_headsigns = {}
      @old_lines_ids = {}
    end

    handle :routes do |line|
      new_line = Line.create({ :agency_id => @agency.id,
                               :src_id => line[:route_id],
                               :short_name => line[:route_short_name],
                               :long_name =>  line[:route_long_name],
                               :short_long_name => shorten_long_name( line ),
                               :bgcolor => line[:route_color],
                               :fgcolor => line[:route_text_color],
                               :usage => line_usage( line ),
                               :picto_url => @lines_picto_urls[line[:route_short_name]],
                               :accessible => @lines_accessible[line[:route_id]],
                               :old_src_id => @old_lines_ids[line[:route_short_name]]
                             })
      @legacy[:line][line[:route_id]] = new_line
      @lines_stops[new_line.id] = {}
      @all_headsigns[new_line.id] = {}
    end

    def pre_calendar 
      @calendar = {}
    end
    handle :calendar do |line|
      id = line[:service_id]
      @calendar[id] = 0
      line.keys.grep(/day$/) do|k|
        if line[k] == "1"
          @calendar[id] |= Calendar.const_get( k.upcase )
        end
      end
    end
    def pre_trips 
      @legacy[:trip] = {}
    end
    handle :trips do |line|
      unless @all_headsigns[@legacy[:line][line[:route_id]].id].has_key? line[:trip_headsign]
        headsign = Headsign.create({ :name => line[:trip_headsign].gsub( /.*\| /, '' ),
                                     :line_id => @legacy[:line][line[:route_id]].id })
        @all_headsigns[@legacy[:line][line[:route_id]].id][line[:trip_headsign]] = headsign
      end
      trip = Trip.create({ :src_id => line[:trip_id],
                           :line_id => @legacy[:line][line[:route_id]].id,
                           :calendar => @calendar[line[:service_id]],
                           :src_route_id => line[:route_id],
                           :headsign_id => @all_headsigns[@legacy[:line][line[:route_id]].id][line[:trip_headsign]].id,
                           :block_id => line[:block_id] })
      @legacy[:trip][line[:trip_id]] = {  
        :line => @legacy[:line][line[:route_id]], 
        :calendar => @calendar[line[:service_id]], 
        :headsign_id => trip.headsign_id, 
        :id => trip.id 
      }
    end

    def pre_stop_times
      @all_stop_times = []
    end
    handle :stop_times do |line|
      if ! @legacy[:trip].has_key?(line[:trip_id])
        #    puts "Missing trip #{line[:trip_id]}"
        next
      end
      # candidate for inlining
      st = StopTime.new({ :stop_id => @legacy[:stops][line[:stop_id]],
                          :line_id => @legacy[:trip][line[:trip_id]][:line].id,
                          :trip_id => @legacy[:trip][line[:trip_id]][:id],
                          :headsign_id => @legacy[:trip][line[:trip_id]][:headsign_id],
                          :calendar => @legacy[:trip][line[:trip_id]][:calendar],
                          :arrival => line[:arrival_time].split(':').inject(0) { |m,v| m = m * 60 + v.to_i },
                          :departure => line[:departure_time].split(':').inject(0) { |m,v| m = m * 60 + v.to_i },
                          :stop_sequence => line[:stop_sequence]
                        })
      @all_stop_times.push( st )
      @lines_stops[st.line_id][st.stop_id] = 1
      if @all_stop_times.length >= NB_RECORDS_TO_INSERT
        flush @all_stop_times
      end
    end
    def post_stop_times
      flush @all_stop_times
    end

    def pre_run
      mlog "loading line icons"
      oda = OpenDataKeolisRennesApi.new( ENV['KEOLIS_API_KEY'], '2.0' )
      result = Yajl::HttpStream.get( oda.get_lines )
      lines_base_url = result['opendata']['answer']['data']['baseurl']
      lines_base_url += '/' unless lines_base_url.end_with?('/')
      @lines_picto_urls = {}
      result['opendata']['answer']['data']['line'].each do|line|
        @lines_picto_urls[line['name']] = lines_base_url + line['picto']
      end
      mlog "loading pos"
      result = Yajl::HttpStream.get( oda.get_pos )
      result['opendata']['answer']['data']['pos'].each do|pos|
        pos['lat'] = pos['latitude'].to_f
        pos['lon'] = pos['longitude'].to_f
        pos['geom'] = Point.from_lon_lat( pos['lon'], pos['lat'], 4326 )
        [ 'latitude', 'longitude', 'phone', 'district' ].each {|k| pos.delete k }
        Pos.create( pos )
      end

      mlog "loading bikestations"
      result = Yajl::HttpStream.get( oda.get_bike_stations )
      result['opendata']['answer']['data']['station'].each do|bs|
        bs['lat'] = bs['latitude'].to_f
        bs['lon'] = bs['longitude'].to_f
        bs['geom'] = Point.from_lon_lat( bs['lon'], bs['lat'], 4326 )
        [ 'latitude', 'longitude', 'state', 'district', 'slotsavailable','bikesavailable','lastupdate' ].each {|k| bs.delete k }
        BikeStation.create( bs )
      end
      
      mlog "loading metrostations"
      result = Yajl::HttpStream.get( oda.get_metro_stations )
      result['opendata']['answer']['data']['station'].each do|ms|
        ms['lat'] = ms['latitude'].to_f
        ms['lon'] = ms['longitude'].to_f
        ms['geom'] = Point.from_lon_lat( ms['lon'], ms['lat'], 4326 )
        ms['src_id'] = ms['id']
        [ 'id', 'latitude', 'longitude', 'hasPlatformDirection1', 'hasPlatformDirection2', 'rankingPlatformDirection1', 'rankingPlatformDirection2', 'floors', 'lastupdate' ].each {|k| ms.delete k }
        MetroStation.create( ms )
      end

      mlog "Removing indexes"
      ActiveRecord::Migration.remove_index( :stop_times, :column => [ :trip_id ] )
      ActiveRecord::Migration.remove_index( :stop_times, :column => [ :line_id, :calendar, :arrival ] )
      ActiveRecord::Migration.remove_index( :lines, :column => [ :short_name ] )
      ActiveRecord::Migration.remove_index( :stops, :column => [ :slug ] )
    end

    def post_run
      ActiveRecord::Base.connection.execute( "UPDATE stop_times SET created_at = now(), updated_at = now()" )

      mlog "Linking lines and stops"
      ActiveRecord::Base.transaction do
        Line.all.each do |line|
          line.stops = @lines_stops[line.id].keys.collect {|stop_id| @all_new_stops[stop_id] }.reject{|x| x.nil? }
          line.save
        end
      end
      mlog "Generating stop line cache"
      ActiveRecord::Base.transaction do
        Stop.all.each do |stop|
          stop.line_ids_cache = stop.lines.collect(&:id).join(",")
          stop.save
        end
      end
      mlog "Adding index for stop_times/trips"
      ActiveRecord::Migration.add_index( :stop_times, [ :trip_id ] )

      check_multiple_trips
      compute_bearings

      mlog "Adding other indexes"
      ActiveRecord::Migration.add_index( :stop_times, [ :line_id, :calendar, :arrival ] )
      ActiveRecord::Migration.add_index( :lines, [ :short_name ] )
      ActiveRecord::Migration.add_index( :stops, [ :slug ] )

      import_kml
      
    end

    def check_multiple_trips
      mlog "This is gonna' be ugly"
      Line.all.each do |line|
        keytrips = {}
        
        line.trips.of_week_day(Calendar::WEEKDAY).each do |trip|
          signer = Digest::SHA2.new
          trip.stop_times.order('arrival ASC').each do |st|
            signer << st.arrival.to_s << st.stop_id.to_s
          end
          unless keytrips.has_key? signer.digest
            keytrips[signer.digest] = []
          end
          keytrips[signer.digest] << trip.id
        end
        mlog "Line #{line.long_name} has #{line.trips.count} trips for #{keytrips.keys.count} digests"
        keytrips.each do |k,ts|
          next if ts.count == 1
          trips = Trip.find( ts )
          final_trip = trips.shift
          final_trip.calendar = trips.inject(final_trip.calendar) { |acc,t| acc |= t.calendar }
          ActiveRecord::Base.transaction do
            final_trip.stop_times.update_all( { :calendar => final_trip.calendar } )
            trips.each do |t| 
              t.stop_times.delete_all
              t.delete
            end
            final_trip.save
          end
        end
        mlog "End of purge for #{line.long_name}"
      end
    end
    def compute_bearings
      mlog "Computing bearings"
      ActiveRecord::Base.transaction do
        Trip.all.each do |trip|
          start = trip.stop_times.order(:arrival).first.stop
          stop = trip.stop_times.order(:arrival).last.stop
          bearing = start.geom.bearing( stop.geom )
          next if bearing.nil?
          base_dir = bearing > 0 ? 'E' : 'W'
          dirs = [ 'N', 'N' + base_dir, 'N' + base_dir, base_dir, base_dir, 'S' + base_dir, 'S' + base_dir, 'S' ] 
          trip.bearing = dirs[ (bearing.abs * 8 / 180).floor ]
          trip.save
        end
      end
    end
    def import_kml
      mlog "Importing KML"
      xml = Nokogiri::XML( File.open( File.join( Rails.root, "tmp", "reseau_star.kml" ) ) )
      xml.remove_namespaces!

      xml.xpath( "//Folder[@id='itin�raires']/Placemark" ).each do |elem|
        #  puts "id " + elem["id"]
        line_short = elem.at_xpath("ExtendedData//SimpleData[@name='li_num']").text
        #  next unless line_short == "8"
        line = Line.find_by_short_name line_short
        next unless line
        #  next unless line.short_name == "8"
        elem.xpath("*//LineString/coordinates").each do |celem|
          coords_str = celem.text
          data = []
          coords_str.split( / / ).each do |coord_str|
            coord = coord_str.split( /,/ )
            data.push( [ coord[1].to_f, coord[0].to_f ] )
          end
#          puts "points: " + data.count.to_s
          encoder = GMapPolylineEncoder.new( :reduce => true, :zoomlevel => 13, :escape => false )
          path = encoder.encode( data )
          #    puts path.to_s
          line.polylines.create( :path => path[:points] )
        end
      end
    end
  end
end
