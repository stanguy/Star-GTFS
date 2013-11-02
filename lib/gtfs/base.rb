# -*- coding: utf-8 -*-

require 'csv'
require 'base_importer'

module Gtfs
  class Base < BaseImporter
    def read_tmp_csv file
      CSV.foreach( File.join( @root, "#{file}.txt" ),
                   :headers => true,
                   :header_converters => :symbol,
                   :encoding => 'UTF-8' ) do |line|
        yield line.to_hash
      end
    end
    
    def line_usage line
      raise NotImplementedError 
    end

    def initialize
      super
      @steps = [ "agency", "feed_info", "stops", "routes", "calendar", "calendar_dates", "trips", "stop_times" ]

      @all_stops = {}
      @cities = {}
      @calendar = {}
      @legacy = Hash.new({})
      @all_stop_times = []
      @lines_stops = {}
      @all_headsigns = {}
      @point_factory = RGeo::Geographic.spherical_factory :srid => 4326

    end
    
    def run
      self.pre_run if self.respond_to?(:pre_run)
      @steps.each do |step|
        mlog step
        [ "pre_", "", "post_" ].each do |prefix|
          method_name = (prefix + step).to_sym
          if self.respond_to? method_name
            ActiveRecord::Base.transaction do
              self.send method_name
            end
          end
        end
      end
      self.post_run if self.respond_to?(:post_run)
      self.internal_post_run
      @agency.centerize! unless @agency.nil?
    end

    class << self
      def handle file_name, &block
        handling_method = file_name.to_s + "_handle"
        send :define_method, handling_method, &block
        send :define_method, file_name.to_sym do
          read_tmp_csv file_name.to_s do |line|
            self.send handling_method, line
          end
        end
      end
    end
  
    # general import utils

    NB_RECORDS_TO_INSERT = 1000
    def flush stop_times
      return if stop_times.empty?
      sql = <<SQL
  INSERT INTO stop_times 
    ( stop_id, line_id, trip_id, headsign_id, calendar_id, arrival, departure, stop_sequence )
  VALUES
SQL
      sql += stop_times.collect do |stoptime|
        "(" + [ stoptime.stop_id, stoptime.line_id, stoptime.trip_id, stoptime.headsign_id, stoptime.calendar_id, stoptime.arrival, stoptime.departure, stoptime.stop_sequence ].join(",") + ")"
      end.join(",")
      ActiveRecord::Base.connection.execute( sql )
      stop_times.clear
    end

    def average array
      array.inject{ |sum, el| sum + el }.to_f / array.size
    end

    def shorten_long_name line
      line[:route_long_name]
    end
        

  # and now, common GTFS handlers
    handle :agency do |line|
      @agency = Agency.where( :name => line[:agency_name] ).first
      if @agency
        @agency.update_attributes( :url => line[:agency_url],
                                   :tz => line[:agency_timezone],
                                   :phone => line[:agency_phone],
                                   :lang => line[:agency_lang],
                                   :city => city,
                                   :ads_allowed => ads_allowed )
      else
        @agency = Agency.create( :name => line[:agency_name],
                                 :url => line[:agency_url],
                                 :tz => line[:agency_timezone],
                                 :phone => line[:agency_phone],
                                 :lang => line[:agency_lang],
                                 :city => city,
                                 :ads_allowed => ads_allowed )
      end
    end

    handle :feed_info do |line|
      @agency.publisher = line[:feed_publisher_name]
      @agency.feed_url = line[:feed_publisher_url]
      @agency.feed_ref = line[:feed_start_date]
    end

    handle :stops do |line|
      next if line.empty?
#      next unless line.has_key?(:stop_code) && line[:stop_code].match(/^[0-9]+$/)
      name = line[:stop_name].downcase.gsub( /[ -_\.]/, '' )
      unless @all_stops.has_key? name
        @all_stops[name] = []
      end
      @all_stops[name] << line
    end

    def post_stops
      valid_stops = {}
      @all_stops.each do |shortname,stops|
        checked_stops = { }
        p = @point_factory.point( stops.first[:stop_lon].to_f, stops.first[:stop_lat].to_f )
        checked_stops[p] = [stops.shift]
        stops.each do |stop|
          found = false
          p2 = @point_factory.point( stop[:stop_lon].to_f, stop[:stop_lat].to_f )
          checked_stops.each do |p,cs_stops|
            if p.distance( p2 ) < 200
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
        stop_city_id = nil
        city_name = self.find_city_by_stop stops
        unless city_name.nil? || city_name.empty?
          unless @cities.has_key? city_name
            @cities[city_name] = City.create({ :name => city_name })
          end
          stop_city_id = @cities[city_name].id
        end
        is_accessible = stops.find_all {|s| s[:wheelchair_boarding] == 0 }.count == 0
        lat = average( stops.collect{|s| s[:stop_lat].to_f } )
        lon = average( stops.collect{|s| s[:stop_lon].to_f } )
        new_stop = Stop.create({ :name => real_name,
                                 :agency_id => @agency.id,
                                 :lat => lat,
                                 :lon => lon,
                                 :geom => @point_factory.point( lon, lat ),
                                 :city_id => stop_city_id,
                                 :accessible => is_accessible })
        stops.each do |stop|
          new_stop.stop_aliases.create({ :src_id => stop[:stop_id],
                                         :src_code => stop[:stop_code],
                                         :src_name => stop[:stop_name],
                                         :src_lat => stop[:stop_lat],
                                         :src_lon => stop[:stop_lon],
                                         :geom => @point_factory.point( stop[:stop_lon], stop[:stop_lat] ),
                                         :description => stop[:stop_desc],
                                         :accessible => stop[:wheelchair_boarding] == 1 })
          @legacy[:stops][stop[:stop_id]] = new_stop.id
        end
        @all_new_stops[new_stop.id] = new_stop
      end
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
                               :accessible => @lines_accessible[line[:route_id]]
                             })
      @legacy[:line][line[:route_id]] = new_line
      @lines_stops[new_line.id] = {}
      @all_headsigns[new_line.id] = {}
      return new_line
    end
    handle :calendar do |line|
      id = line[:service_id]
      days = 0
      line.keys.grep(/day$/) do|k|
        if line[k] == "1"
          days |= Calendar.const_get( k.upcase )
        end
      end
      start_d = Date.strptime( line[:start_date], '%Y%m%d' )
      unless start_d.monday?
        ref = if start_d.sunday? then 7.days else start_d.wday.days end
        start_d = ( start_d - ( ref - 1.day ) ).to_date
      end
      end_d = Date.strptime( line[:end_date], '%Y%m%d' )
      unless end_d.sunday?
        end_d = ( end_d + ( 7 - end_d.wday ).days ).to_date
      end
      @calendar[id] = Calendar.create( src_id: id,
                                       days: days,
                                       start_date: start_d, 
                                       end_date: end_d )
    end

    handle :calendar_dates do |line|
      if not @calendar.has_key? line[:service_id]
        print "Missing calendar for exception ? (" + line[:service_id] + ")"
      end
      CalendarDate.create( calendar_id: @calendar[ line[:service_id] ].id,
                           exception_date: Date.strptime( line[:date], "%Y%m%d" ),
                           exclusion: "2" == line[:exception_type] )
    end

    def post_calendar_dates
      cal_sums = {}
      @calendar.each do |src_id,cal|
        cal_key = [ cal.to_s, cal.calendar_dates.join("_") ].join("/")
        if cal_sums.has_key? cal_key
          CalendarDate.delete_all calendar_id: cal.id
          cal.delete
          @calendar[src_id] = cal_sums[cal_key]
        else 
          cal_sums[cal_key] = cal
        end
      end
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


    handle :stop_times do |line|
      next unless line[:stop_id] =~ /[0-9]+/ # stops that shouldn't be
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

    # others

    def internal_post_run
      mlog "Linking lines and stops"
      ActiveRecord::Base.transaction do
        @agency.lines.each do |line|
          next unless @lines_stops.has_key? line.id
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
      compute_bearings
    end
    
    def compute_bearings
      mlog "Computing bearings"
      ActiveRecord::Base.transaction do
        Trip.all.each do |trip|
          start = trip.stop_times.order(:arrival).first.stop
          stop = trip.stop_times.order(:arrival).last.stop
          bearing = GTFSPoint::bearing( start.geom, stop.geom )
          next if bearing.nil?
          base_dir = bearing > 0 ? 'E' : 'W'
          dirs = [ 'N', 'N' + base_dir, 'N' + base_dir, base_dir, base_dir, 'S' + base_dir, 'S' + base_dir, 'S' ] 
          trip.bearing = dirs[ (bearing.abs * 8 / 180).floor ]
          trip.save
        end
      end
    end
  end
end
