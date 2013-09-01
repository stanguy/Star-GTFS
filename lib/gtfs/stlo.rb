# -*- coding: utf-8 -*-
require 'csv'
require 'base_importer'
require 'st_lo_importer'
require 'stop_registry'

require 'gmap_polyline_encoder'
require 'point'

class StLoStopRegistry < StopRegistry
  alias parent_clean_up clean_up
  def clean_up str
    if matches = str.match( /^(?:.*-)?SAINT LO (.*)$/ )
      parent_clean_up matches[1]
    elsif matches = str.match( /^(?:.*-)?ST GEORGES MONTCOCQ (.*)$/ )
      parent_clean_up matches[1]
    elsif matches = str.match( /^(?:AGNEAUX-)?AGNEAUX (.*)$/ )
      parent_clean_up matches[1]
    else
      parent_clean_up str
    end
  end
end

module Gtfs 
  class StLo < BaseImporter
    def fix_stlo_headsign headsign
      headsign.split(/ (è|=>|:) /).pop
    end
    

    def import_stoptimes line, headsign_str, trips
      if headsign_str.blank? || headsign_str.nil?
        raise "Empty headsign at #{caller(1)[0]}"
      end
      headsign = Headsign.find_or_create_by_name_and_line_id( fix_stlo_headsign(headsign_str),
                                                              line.id )
      headsign.save
      trips.each do |mtrip|
        mtrip.each do |calendar_days,times|
          if @calendars.has_key? calendar_days
            calendar = @calendars[calendar_days]
          else
            calendar = @calendars[calendar_days] = Calendar.create( src_id: 'cal_' + calendar_days.to_s,
                                                                    days: calendar_days,
                                                                    start_date: Date::civil( 2013, 9, 2 ),
                                                                    end_date: Date::civil( 2014, 7, 6 ) )
          end
          trip = Trip.create( :line => line, 
                              :calendar => calendar,
                              :headsign => headsign )
          times.each_with_index do |st,idx|
            StopTime.create( :stop => st[:s],
                             :line => line,
                             :trip => trip,
                             :headsign => headsign,
                             :arrival => st[:t],
                             :departure => st[:t],
                             :calendar => calendar,
                             :stop_sequence => idx )
          end
        end
      end
      line.stops = Stop.find( StopTime.where( :line_id => line.id ).collect(&:stop_id) )
    end
    def check_value cell, expected, skip = 0
      unless cell.to_s.strip == expected
        raise "Assertion failed: got '#{cell.to_s}' != '#{expected.to_s}' expected at #{caller(1)[skip]}" 
      end
    end
    
    def check_values dataset, checks
      checks.each do |c|
        x, y, v = c
        check_value dataset[x][y], v, 3
      end
    end
    
    def run
      
      agency_info = { :publisher => "Veolia Transdev",
        :feed_ref => "20130902",
        :tz => "Europe/Paris",
        :lang => :fr,
        :city => "Saint Lô",
        :ads_allowed => false 
      }
      @agency = Agency.where( :name => "TUSA" ).first
      if @agency
        @agency.update_attributes( agency_info )
      else
        @agency = Agency.create( agency_info.merge( { :name => "TUSA" } ) )
      end

      @calendars = { }
      
      stop_registry = StLoStopRegistry.new @agency
      
      #####################################################################
      ###                           L3                                  ###
      #####################################################################
      mlog "Importing line 3"
      l3 = Line.create( :short_name => "3",
                        :agency_id => @agency.id,
                        :long_name => "Saint-Lô-Bois Ardent / Grandin <> Saint-Georges-Montcocq",
                        :short_long_name => "Bois Ardent / Grandin <> Saint-Georges-Montcocq",
                        :fgcolor => '000000',
                        :bgcolor => 'ccffcc',
                        :src_id => "3",
                        :accessible => false,
                        :usage => :urban )
      
      data_l3 = CSV.read( File.join( self.root, 'Ligne3_2013-2014.csv' ), :encoding => 'UTF-8')

      check_value data_l3[5][1], "7:05"
      check_value data_l3[29][1], "|"
      check_value data_l3[5][22], "|"
      check_value data_l3[29][22], "|"    
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 1
      importer.default_calendar = Calendar::MONDAY | Calendar::TUESDAY | Calendar::THURSDAY | Calendar::FRIDAY
      importer.stops_range = 5..29
      importer.stop_col = 0
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[2][0], trips

      check_value data_l3[33][1], "7:30"
      check_value data_l3[56][1], "7:48"
      check_value data_l3[33][22], "|"
      check_value data_l3[56][22], "19:36"      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 1
      importer.default_calendar = Calendar::MONDAY | Calendar::TUESDAY | Calendar::THURSDAY | Calendar::FRIDAY
      importer.stops_range = 33..56
      importer.stop_col = 0

      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[30][0], trips
            
      check_value data_l3[60][1], "7:05"
      check_value data_l3[84][1], '|'
      check_value data_l3[60][22], "|"
      check_value data_l3[84][22], '|'
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.stops_range = 60..84
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[57][0], trips

      check_value data_l3[88][1], "7:30"
      check_value data_l3[111][1], "7:48"
      check_value data_l3[88][22], "19:18"
      check_value data_l3[111][22], "19:36"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.stops_range = 88..111
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[85][0], trips      

      check_value data_l3[115][1], "8:30"
      check_value data_l3[139][1], "|"
      check_value data_l3[115][10], "17:45"
      check_value data_l3[139][10], "18:09"
      check_value data_l3[115][11], "|"
      check_value data_l3[139][11], "|"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 115..139
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[112][0], trips      

      check_value data_l3[143][1], "8:00"
      check_value data_l3[166][1], "8:18"
      check_value data_l3[143][10], "|"
      check_value data_l3[166][10], "17:31"
      check_value data_l3[143][11], "|"
      check_value data_l3[166][11], "|"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 143..166
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[140][0], trips      
      data_l3 = nil

      #####################################################################
      ###                           L1                                  ###
      #####################################################################
      mlog "Importing line 1"
      l1 = Line.create( :short_name => "1",
                        :agency_id => @agency.id,
                        :long_name => "Saint-Lô-Colombes <> Agneaux-Villechien / Demeurance",
                        :short_long_name => "Colombes <> Agneaux-Villechien / Demeurance",
                        :fgcolor => 'ffffff',
                        :bgcolor => 'ff0000',
                        :src_id => '1',
                        :accessible => false,
                        :usage => :urban )

      data_l1 = CSV.read( File.join( self.root, 'Ligne1_2013-2014.csv' ), :encoding => 'UTF-8')

      check_value data_l1[5][1], "6:59"
      check_value data_l1[40][1], "7:28"
      check_value data_l1[5][31], "|"
      check_value data_l1[40][31], "19:58"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 5..40
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[2][0], trips
      
      check_value data_l1[44][1], "6:30"
      check_value data_l1[75][1], "6:59"
      check_value data_l1[44][31], "19:03"
      check_value data_l1[75][31], "|"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 44..75
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[41][0], trips

      check_value data_l1[79][1], "|"
      check_value data_l1[114][1], "8:40"
      check_value data_l1[79][22], "19:35"
      check_value data_l1[114][22], "20:08"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 79..114
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[76][0], trips
      
      check_value data_l1[118][1], "7:38"
      check_value data_l1[149][1], "|"
      check_value data_l1[118][22], "19:05"
      check_value data_l1[149][22], "19:34"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 118..149
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[115][0], trips
      data_l1 = nil

      #####################################################################
      ###                           L2                                  ###
      #####################################################################
      mlog "Importing line 2"
      l2 = Line.create( :short_name => "2",
                        :agency_id => @agency.id,
                        :long_name => "Saint-Lô-Conseil Général < > Saint-Lô-La Madeleine",
                        :short_long_name => "Conseil Général < > La Madeleine",
                        :fgcolor => 'ffffff',
                        :bgcolor => '99ccff',
                        :src_id => '2',
                        :accessible => false,
                        :usage => :urban )

      data_l2 = CSV.read( File.join( self.root, 'Ligne2_2013-2014.csv' ), :encoding => 'UTF-8')
      
      check_value data_l2[5][1], "6:56"
      check_value data_l2[33][1], "7:22"
      check_value data_l2[5][21], "19:41"
      check_value data_l2[33][21], "20:07"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 5..33
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[2][0], trips

      check_value data_l2[37][1], "6:25"
      check_value data_l2[66][1], "6:52"
      check_value data_l2[37][21], "19:10"
      check_value data_l2[66][21], "19:39"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 37..66
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[34][0], trips

      check_value data_l2[70][1], "8:32"
      check_value data_l2[98][1], "8:58"
      check_value data_l2[70][11], "19:22"
      check_value data_l2[98][11], "19:52"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 70..98
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[67][0], trips
      
      check_value data_l2[102][1], "8:00"
      check_value data_l2[131][1], "8:30"
      check_value data_l2[102][11], "18:50"
      check_value data_l2[131][11], "19:19"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 102..131
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[99][0], trips
      data_l2 = nil
      
      if true
      mlog "Importing school lines"
      
      data_s1 = CSV.read( File.join( self.root, 'S1_2013-2014.csv' ), :encoding => 'UTF-8' )    
      
      l1 = Line.create( :short_name => "S1",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Colombes / Pasteur / Bon Sauveur / Lavalley",
                        :short_long_name => "Scolaire Colombes / Lavalley",
                        :fgcolor => 'ffffff',
                        :bgcolor => 'ff0000',
                        :src_id => 'SCL',
                        :accessible => false,
                        :usage => :special )

      check_value data_s1[5][1], "7:25"
      check_value data_s1[31][1], "7:50"
      check_value data_s1[5][2], "13:00"
      check_value data_s1[31][2], "13:22"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY
      importer.first_trip_col = 1
      importer.stops_range = 5..31
      importer.stop_col = 0
      trips = importer.import( data_s1 )
      import_stoptimes l1, "Colombes - Lavalley", trips
      
      check_value data_s1[35][1], "12:05"
      check_value data_s1[61][1], "12:32"
      check_value data_s1[35][2], "16:40"
      check_value data_s1[61][2], "17:02"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY
      importer.first_trip_col = 1
      importer.stops_range = 35..61
      importer.stop_col = 0
      trips = importer.import( data_s1 )
      import_stoptimes l1, "Lavalley - Colombes", trips

      check_value data_s1[65][1], "7:25"
      check_value data_s1[91][1], "7:50"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.first_trip_col = 1
      importer.stops_range = 65..91
      importer.stop_col = 0
      trips = importer.import( data_s1 )
      import_stoptimes l1, "Colombes - Lavalley", trips
      
      check_value data_s1[95][1], "12:05"
      check_value data_s1[121][1], "12:32"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.first_trip_col = 1
      importer.stops_range = 35..61
      importer.stop_col = 0
      trips = importer.import( data_s1 )
      import_stoptimes l1, "Lavalley - Colombes", trips

      l2 = Line.create( :short_name => "S2",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Agneaux / Lavalley",
                        :short_long_name => "Scolaire Agneaux / Lavalley",
                        :fgcolor => '000000',
                        :bgcolor => '99ccff',
                        :src_id => 'SAL',
                        :accessible => false,
                        :usage => :special )
 
      data_s2 = CSV.read( File.join( self.root, 'S2_2013-2014.csv' ), :encoding => 'UTF-8' )    

      check_value data_s2[5][1], "12:05"
      check_value data_s2[24][1], "12:30"
      check_value data_s2[5][2], "16:40"
      check_value data_s2[24][2], "17:00"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY
      importer.first_trip_col = 1
      importer.stops_range = 5..24
      importer.stop_col = 0
      trips = importer.import( data_s2 )
      import_stoptimes l2, "Lavalley - Demeurance", trips
      
      check_value data_s2[28][1], "12:05"
      check_value data_s2[47][1], "12:30"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.first_trip_col = 1
      importer.stops_range = 28..47
      importer.stop_col = 0
      trips = importer.import( data_s2 )
      import_stoptimes l2, "Lavalley - Demeurance", trips
      
      l3 = Line.create( :short_name => "S3",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Bon Sauveur / Lavalley / St Georges Montcocq",
                        :short_long_name => "Scolaire Bon Sauveur / Lavalley / St Georges Montcocq",
                        :fgcolor => '000000',
                        :bgcolor => '99cc00',
                        :src_id => 'SBSSGM',
                        :accessible => false,
                        :usage => :special )

      data_s3 = CSV.read( File.join( self.root, 'S3_2013-2014.csv' ), :encoding => 'UTF-8' )    

      check_value data_s3[5][1], "12:00"
      check_value data_s3[16][1], "12:18"
      check_value data_s3[5][2], "|"
      check_value data_s3[16][2], "16:51"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY
      importer.first_trip_col = 1
      importer.stops_range = 5..16
      importer.stop_col = 0
      trips = importer.import( data_s3 )
      import_stoptimes l3, "Collège Bechevel - St Georges", trips

      check_value data_s3[20][1], "12:00"
      check_value data_s3[31][1], "12:18"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.first_trip_col = 1
      importer.stops_range = 20..31
      importer.stop_col = 0
      trips = importer.import( data_s3 )
      import_stoptimes l3, "Collège Bechevel - St Georges", trips
      
      l4 = Line.create( :short_name => "S4",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Agneaux / Le Verrier",
                        :short_long_name => "Scolaire Agneaux / Le Verrier",
                        :fgcolor => 'ffffff',
                        :bgcolor => '333399',
                        :src_id => 'SALV',
                        :accessible => false,
                        :usage => :special )

      data_s4 = CSV.read( File.join( self.root, 'S4_2013-2014.csv' ), :encoding => 'UTF-8' )    

      check_value data_s4[5][1], "7:25"
      check_value data_s4[24][1], "7:50"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY
      importer.first_trip_col = 1
      importer.stops_range = 5..24
      importer.stop_col = 0
      trips = importer.import( data_s4 )
      import_stoptimes l4, "Agneaux - Le Verrier", trips

      check_value data_s4[28][1], "7:25"
      check_value data_s4[47][1], "7:50"

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEDNESDAY
      importer.first_trip_col = 1
      importer.stops_range = 28..47
      importer.stop_col = 0
      trips = importer.import( data_s4 )
      import_stoptimes l4, "Agneaux - Le Verrier", trips


      end

      mlog "Importing KML file"

      xml = Nokogiri::XML( File.open( File.join( self.root, "doc.kml" ) ) )
      xml.remove_namespaces!

      stops = []
      missings = []

      @point_factory = RGeo::Geographic.spherical_factory :srid => 4326
      xml.xpath("//Folder/Placemark").each do |elem|
        point_coord_elem = elem.at_xpath( "Point/coordinates" )
        line_coord_elem = elem.at_xpath( "LineString/coordinates" )
        if not point_coord_elem.nil?
          coords = point_coord_elem.text.split(/,/)
          name = elem.xpath( "name" ).text
          if match = name.match( /^([0-9A-Z]{3}\d{2}[AR]) \(([^)]*)\)?$/ )
            src_id = match[1]
            name = match[2].strip
          elsif match = name.match( /^(.*) \(([A-Z]{3}\d{2}[AR])\)/ )
            src_id = match[2]
            name = match[1].strip
          else
            puts "unable to understand #{name}"
          end
          if match = name.match( /^Saint Georges (.*)$/ )
            name = match[1]
          end
          stop = Stop.find_by_name name
          if stop.nil?
            if match = name.match( /^(?:[A-Z]|le|la|les) (.*)$/i )
              qname = match[1].downcase
            else
              qname = name.downcase
            end
            case qname 
            when "buotl" 
              qname = "buot"
            when "madelaine"
              qname = "madeleine"
            end
            stop = Stop.where( "ts_rank_cd( '{0.1, 0.2, 0.4, 1.0}', to_tsvector('french',public.unaccent_string(name)), plainto_tsquery( 'french', ? ) ) > 0", qname ).first
          end
          if stop.nil?
            missings << name
          else
            stop.stop_aliases.create({ :src_id => src_id,
                                       :src_code => src_id,
                                       :src_name => name,
                                       :src_lat => coords[1],
                                       :src_lon => coords[0],
                                       :geom => @point_factory.point( coords[0], coords[1] )
                                     })
            stops << stop
          end
        elsif not line_coord_elem.nil?
          line = @agency.lines.find_by_short_name elem.at_xpath("name").text.to_i.to_s
          data = []
          line_coord_elem.text.strip.split( / / ).each do |coord_str|
            coord = coord_str.split( /,/ )
            data.push( [ coord[1].to_f, coord[0].to_f ] )
          end
          encoder = GMapPolylineEncoder.new( :reduce => true, :zoomlevel => 13, :escape => false )
          path = encoder.encode( data )
          #    puts path.to_s
          line.polylines.create( :path => path[:points] )
        end
      end

      #puts stops.uniq.count #each do |s| puts s.inspect end
      #puts missings.uniq.count
      #puts missings.uniq

      mlog "Computing positions and bearings"
      
      stops.uniq.each do |stop|
        next if stop.stop_aliases.count == 0
        stop.geom = stop.stop_aliases.where( 'geom is not null' ).select( "AsText(ST_Centroid(ST_Collect(geom::geometry))) AS center" )[0].center
        stop.lat = stop.geom.lat
        stop.lon = stop.geom.lon
        stop.save
      end


      ActiveRecord::Base.transaction do
        Trip.all.each do |trip|
          next if trip.stop_times.empty?
          start = trip.stop_times.order(:arrival).first.stop
          stop = trip.stop_times.order(:arrival).last.stop
          next if start.geom.nil? or stop.geom.nil?
          bearing = GTFSPoint::bearing( start.geom, stop.geom )
          next if bearing.nil?
          base_dir = bearing > 0 ? 'E' : 'W'
          dirs = [ 'N', 'N' + base_dir, 'N' + base_dir, base_dir, base_dir, 'S' + base_dir, 'S' + base_dir, 'S' ] 
          trip.bearing = dirs[ (bearing.abs * 8 / 180).floor ]
          trip.save
        end
      end


      ActiveRecord::Base.transaction do
        Stop.all.each do |stop|
          stop.line_ids_cache = stop.lines.collect(&:id).join(",")
          stop.save
        end
      end
      @agency.centerize!

      [ Date::civil( 2013, 11, 1 ),
        Date::civil( 2013, 11, 11 ),
        Date::civil( 2013, 12, 25 ),
        Date::civil( 2014, 1, 1 ),
        Date::civil( 2013, 4, 21 ),
        Date::civil( 2013, 5, 1 ),
        Date::civil( 2013, 5, 8 ),
        Date::civil( 2013, 5, 29 ),
        Date::civil( 2013, 6, 9 ) ].each do |date|
        @calendars.each do |days,calendar|
          CalendarDate.create( calendar_id: calendar.id,
                               exception_date: date,
                               exclusion: true )
        end
      end
    end
  end
end
