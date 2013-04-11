# -*- coding: utf-8 -*-

require 'point'
require 'opendata_api'
require 'gmap_polyline_encoder'
require 'net/http'


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
    
    def initialize
      super
      @steps.insert( @steps.index("routes") + 1, "routes_additionals" )
      @steps.insert( @steps.index("routes"), "routes_extensions" )
      # 
    end

    def post_agency
      KeolisApiCollector.create agency_id: @agency.id
    end

    def find_city_by_stop stop_lines
      stop_lines.first[:stop_desc]
    end 

    def pre_routes_extensions
      @lines_accessible = Hash.new(false)
    end
    handle :routes_extensions do |line|
      @lines_accessible[line[:route_id]] = line[:route_accessible].to_i == 1
    end

    handle :routes_additionals do |line|
      Line.create( agency_id: @agency.id,
                   src_id: line[:route_id],
                   short_name: line[:route_short_name],
                   long_name: line[:route_long_name],
                   short_long_name: shorten_long_name( line ),
                   bgcolor: line[:route_color],
                   fgcolor: line[:route_text_color],
                   usage: :special,
                   :accessible => false, # because we don't know
                   hidden: true )
    end

    handle :routes do |line|
      new_line = super line
      if File.exists?( File.join( @root, line[:route_short_name] + ".png" ) )
        new_line.picto_url = File.open( File.join( @root, line[:route_short_name] + ".png" ) )
        new_line.save
      elsif @lines_picto_urls.has_key? line[:route_short_name]
        new_line.remote_picto_url_url = @lines_picto_urls[line[:route_short_name]]
        new_line.save
      end
    end

    def pre_run
      mlog "loading line icons"
      oda = OpenDataKeolisRennesApi.new( ENV['KEOLIS_API_KEY'], '2.0' )
      result = JSON.parse Net::HTTP.get( oda.get_lines )
      lines_base_url = result['opendata']['answer']['data']['baseurl']
      lines_base_url += '/' unless lines_base_url.end_with?('/')
      @lines_picto_urls = {}
      result['opendata']['answer']['data']['line'].each do|line|
        @lines_picto_urls[line['name']] = lines_base_url + line['picto']
      end
      mlog "loading pos"
      result = JSON.parse Net::HTTP.get( oda.get_pos )
      result['opendata']['answer']['data']['pos'].each do|pos|
        pos['lat'] = pos['latitude'].to_f
        pos['lon'] = pos['longitude'].to_f
        pos['geom'] = @point_factory.point( pos['lon'], pos['lat'] )
        [ 'latitude', 'longitude', 'phone', 'district' ].each {|k| pos.delete k }
        Pos.create( pos )
      end

      mlog "loading bikestations"
      result = JSON.parse Net::HTTP.get( oda.get_bike_stations )
      result['opendata']['answer']['data']['station'].each do|bs|
        bs['lat'] = bs['latitude'].to_f
        bs['lon'] = bs['longitude'].to_f
        bs['geom'] = @point_factory.point( bs['lon'], bs['lat'] )
        [ 'latitude', 'longitude', 'state', 'district', 'slotsavailable','bikesavailable','lastupdate' ].each {|k| bs.delete k }
        BikeStation.create( bs )
      end
      
      mlog "loading metrostations"
      result = JSON.parse Net::HTTP.get( oda.get_metro_stations )
      result['opendata']['answer']['data']['station'].each do|ms|
        ms['lat'] = ms['latitude'].to_f
        ms['lon'] = ms['longitude'].to_f
        ms['geom'] = @point_factory.point( ms['lon'], ms['lat'] )
        ms['src_id'] = ms['id']
        [ 'id', 'latitude', 'longitude', 'hasPlatformDirection1', 'hasPlatformDirection2', 'rankingPlatformDirection1', 'rankingPlatformDirection2', 'floors', 'lastupdate' ].each {|k| ms.delete k }
        MetroStation.create( ms )
      end

      mlog "Removing indexes"
      begin
        ActiveRecord::Migration.remove_index( :stop_times, :column => [ :trip_id ] )
        ActiveRecord::Migration.remove_index( :stop_times, :column => [ :line_id, :calendar_id, :arrival ] )
        ActiveRecord::Migration.remove_index( :lines, :column => [ :short_name ] )
        ActiveRecord::Migration.remove_index( :stops, :column => [ :slug ] )
      rescue
      end
    end

    def post_run
      mlog "Adding index for stop_times/trips"
      ActiveRecord::Migration.add_index( :stop_times, [ :trip_id ] )

      check_multiple_trips

      mlog "Adding other indexes"
      ActiveRecord::Migration.add_index( :stop_times, [ :line_id, :calendar_id, :arrival ] )
      ActiveRecord::Migration.add_index( :lines, [ :short_name ] )
      ActiveRecord::Migration.add_index( :stops, [ :slug ] )

      import_kml
      
    end

    def check_multiple_trips
      mlog "This is gonna' be ugly"
      @agency.lines.each do |line|
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
          all_calendars = trips.collect(&:calendar).uniq
          final_trip = trips.shift
          all_days = all_calendars.inject(0) { |acc,cal| acc |= cal.days }
          final_trip.calendar = Calendar.where( start_date: final_trip.calendar.start_date,
                                                end_date: final_trip.calendar.end_date,
                                                days: all_days ).first_or_create
          all_exceptions = all_calendars.collect(&:calendar_dates).flatten.uniq
          if final_trip.calendar.calendar_dates.count == 0 and all_exceptions.count > 0
            all_exceptions.collect do |cd|
              { exclusion: cd.exclusion, exception_date: cd.exception_date }
            end.uniq.each do |bcd|
              bcd[:calendar_id] = final_trip.calendar.id
              CalendarDate.create( bcd )
            end
          end
          ActiveRecord::Base.transaction do
            final_trip.stop_times.update_all( { :calendar_id => final_trip.calendar.id } )
            trips.each do |t| 
              StopTime.delete_all trip_id: t.id
              t.delete
            end
            final_trip.save
          end
        end
        mlog "End of purge for #{line.long_name}"
      end
      Calendar.all.select { |c| c.trips.count == 0 }.map(&:delete)
    end
    def import_kml
      mlog "Importing KML"
      xml = Nokogiri::XML( File.open( File.join( self.root, "reseau_star.kml" ) ) )
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
