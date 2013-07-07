# -*- coding: utf-8 -*-
require 'csv'
require 'base_importer'
require 'st_lo_importer'
require 'stop_registry'

require 'gmap_polyline_encoder'
require 'point'

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
                                                                    start_date: Date::civil( 2013, 7, 8 ),
                                                                    end_date: Date::civil( 2013, 9, 1 ) )
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
        :feed_ref => "20130708",
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
      
      stop_registry = StopRegistry.new @agency
      
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
      
      data_l3 = CSV.read( File.join( self.root, 'Ligne3_ETE2013.csv' ), :encoding => 'UTF-8')
      check_value data_l3[7][1], "6:55"
      check_value data_l3[35][1], "|"
      check_value data_l3[7][13], "19:25"
      check_value data_l3[35][13], "|"
            
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 1
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 7..35
      importer.stop_col = 0
      trips = importer.import(data_l3)
      
      import_stoptimes l3, data_l3[3][0], trips
      

      check_value data_l3[42][1], "7:25"
      check_value data_l3[67][1], "7:47"
      check_value data_l3[42][12], "|"
      check_value data_l3[67][12], "19:20"      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 1
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 42..67
      importer.stop_col = 0
      
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[38][0], trips
            
      check_value data_l3[74][1], "8:15"
      check_value data_l3[102][1], '|'
      check_value data_l3[74][12], "19:15"
      check_value data_l3[102][12], '|'
      
      check_value data_l3[109][1], "7:45"
      check_value data_l3[134][1], "8:07"
      check_value data_l3[109][12], "|"
      check_value data_l3[134][12], "19:08"
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 74..102
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[70][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 109..134
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l3)
      import_stoptimes l3, data_l3[105][0], trips      
      
      #####################################################################
      ###                           L1                                  ###
      #####################################################################
      mlog "Importing line 1"
      l1 = Line.create( :short_name => "1",
                        :agency_id => @agency.id,
                        :long_name => "Saint-Lô-Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                        :short_long_name => "Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                        :fgcolor => 'ffffff',
                        :bgcolor => 'ff0000',
                        :src_id => '1',
                        :accessible => false,
                        :usage => :urban )

      data_l1 = CSV.read( File.join( self.root, 'Ligne1_ETE2013.csv' ), :encoding => 'UTF-8')
      
      check_value data_l1[7][1], "|"
      check_value data_l1[39][1], "7:18"
      check_value data_l1[7][20], "19:35"
      check_value data_l1[39][20], "20:04"
      
      check_value data_l1[46][1], "6:20"
      check_value data_l1[76][1], "|"
      check_value data_l1[46][20], "19:00"
      check_value data_l1[76][20], "19:29"


      check_value data_l1[84][1], "|"
      check_value data_l1[116][1], "8:18"
      check_value data_l1[84][18], "19:35"
      check_value data_l1[116][18], "20:04"
      
      
      
      check_value data_l1[123][1], "7:20"
      check_value data_l1[153][1], "|"
      check_value data_l1[123][18], "19:00"
      check_value data_l1[153][18], "19:29"
      
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 7..39
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[3][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 46..76
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[42][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 84..116
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[80][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 123..153
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l1)
      import_stoptimes l1, data_l1[119][0], trips
      
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

      data_l2 = CSV.read( File.join( self.root, 'Ligne2_ETE2013.csv' ), :encoding => 'UTF-8')
      
      check_value data_l2[7][1], "7:45"
      check_value data_l2[36][1], "8:13"
      check_value data_l2[7][12], "19:40"
      check_value data_l2[36][12], "20:08"
      
      check_value data_l2[43][1], "7:15"
      check_value data_l2[71][1], "7:44"
      check_value data_l2[43][12], "19:10"
      check_value data_l2[71][12], "19:39"

      check_value data_l2[77][1], "8:50"
      check_value data_l2[106][1], "9:18"
      check_value data_l2[77][11], "19:40"
      check_value data_l2[106][11], "20:08"
      
      
      check_value data_l2[113][1], "8:20"
      check_value data_l2[141][1], "8:49"
      check_value data_l2[113][11], "19:10"
      check_value data_l2[141][11], "19:39"
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 7..36
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[3][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 43..71
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[39][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 77..106
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[73][0], trips
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 113..141
      importer.stop_col = 0
      importer.first_trip_col = 1
      trips = importer.import(data_l2)
      import_stoptimes l2, data_l2[109][0], trips
      
      if false
      mlog "Importing school lines"
      
      data_scolaires = CSV.read( File.join( self.root, 'service scolaire rentree sept dec 2012 - sheet.csv' ), :encoding => 'UTF-8' )
      
      check_values data_scolaires, [
                                    # s1a
                                    [ 8, 1, "7:25" ],
                                    [ 34, 1, "7:50" ],
                                    # s1r
                                    [ 8, 5, "12:05" ],
                                    [ 34, 5, "12:32" ],
                                    # s2r
                                    [ 8, 11, "12:05" ],
                                    [ 27, 11, "12:30" ],
                                    # s3a
                                    [ 8, 15, "12:00" ],
                                    [ 19, 15, "12:18" ],
                                    # s4a
                                    [ 8, 19, "7:25" ],
                                    [ 27, 19, "7:50" ],
                                   ]
      
      
      ls = Line.create( :short_name => "S1",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Colombes / Pasteur / Bon Sauveur / Lavalley",
                        :short_long_name => "Scolaire Colombes / Lavalley",
                        :fgcolor => 'ffffff',
                        :bgcolor => 'ff0000',
                        :src_id => 'SCL',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 1
      importer.stops_range = 8..34
      importer.stop_col = 0
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 8..34, 2 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Colombes - Lavalley", trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 5
      importer.stops_range = 8..34
      importer.stop_col = 4
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 8..34, 6 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Lavalley - Colombes", trips
      
      ls = Line.create( :short_name => "S2",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Agneaux / Lavalley",
                        :short_long_name => "Scolaire Agneaux / Lavalley",
                        :fgcolor => '000000',
                        :bgcolor => '99ccff',
                        :src_id => 'SAL',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 11
      importer.stops_range = 8..27
      importer.stop_col = 10
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 8..27, 12 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Demeurance - Lavalley", trips
      
      
      ls = Line.create( :short_name => "S3",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Bon Sauveur / Lavalley / St Georges Montcocq",
                        :short_long_name => "Scolaire Bon Sauveur / Lavalley / St Georges Montcocq",
                        :fgcolor => '000000',
                        :bgcolor => '99cc00',
                        :src_id => 'SBSSGM',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 15
      importer.stops_range = 8..19
      importer.stop_col = 14
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 8..19, 16 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Collège Bechevel - St Georges", trips
      
      ls = Line.create( :short_name => "S4",
                        :agency_id => @agency.id,
                        :long_name => "Scolaire Agneaux / Le Verrier",
                        :short_long_name => "Scolaire Agneaux / Le Verrier",
                        :fgcolor => 'ffffff',
                        :bgcolor => '333399',
                        :src_id => 'SALV',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 19
      importer.stops_range = 8..27
      importer.stop_col = 18
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Agneaux - Le Verrier", trips


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
            when "ferronniere"
              qname = "ferroniere"
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

      [ Date::civil( 2013, 7, 14 ), 
        Date::civil( 2013, 8, 15 ) ].each do |date|
        @calendars.each do |days,calendar|
          CalendarDate.create( calendar_id: calendar.id,
                               exception_date: date,
                               exclusion: true )
        end
      end
    end
  end
end
