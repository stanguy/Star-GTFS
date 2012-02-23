# -*- coding: utf-8 -*-
require 'csv'
require 'st_lo_importer'
require 'stop_registry'

require 'gmap_polyline_encoder'
require 'point'

module Gtfs 
  class StLo < Base
    def fix_stlo_headsign headsign
      headsign.split(/ (è|=>) /).pop
    end
    

    def import_stoptimes line, headsign_str, trips
      if headsign_str.blank? || headsign_str.nil?
        raise "Empty headsign"
      end
      headsign = Headsign.create( :name => fix_stlo_headsign(headsign_str),
                                  :line => line )
      trips.each do |mtrip|
        mtrip.each do |calendar,times|
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
    def check_value cell, expected
      unless cell == expected
        puts "'#{cell.to_s}' != '#{expected.to_s}'"
        raise "Assertion failed" 
      end
    end
    
    def check_values dataset, checks
      checks.each do |c|
        x, y, v = c
        check_value dataset[x][y], v
      end
    end
    
    def run
      
      @agency = Agency.create( :name => "TUAS",
                               :tz => "Europe/Paris",
                               :lang => :fr,
                               :city => "Saint Lô",
                               :ads_allowed => false )

      
      stop_registry = StopRegistry.new
      
      #####################################################################
      ###                           L3                                  ###
      #####################################################################
      mlog "Importing line 3"
      l3 = Line.create( :short_name => "3",
                        :agency_id => @agency.id,
                        :long_name => "Saint-Lô-Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie",
                        :short_long_name => "Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie",
                        :fgcolor => '#000000',
                        :bgcolor => '#ccffcc',
                        :src_id => "3",
                        :accessible => false,
                        :usage => :urban )
      
      data_l3_semaine = CSV.read('tmp/ligne_3_sept2011_semaine.csv', :encoding => 'UTF-8')
      check_value data_l3_semaine[8][3], "7:00"
      check_value data_l3_semaine[38][3], "-"
      check_value data_l3_semaine[8][41], "19:00"
      check_value data_l3_semaine[38][41], "-"
      # exceptions 
      # Mon/Tue/Thu/Fri
      check_value data_l3_semaine[32][13], "9:52"
      check_value data_l3_semaine[38][13], "10:00"
      check_value data_l3_semaine[32][39], "18:57"
      check_value data_l3_semaine[38][39], "19:05"
      # Wed
      check_value data_l3_semaine[32][27], "14:52"
      check_value data_l3_semaine[38][27], "15:00"
      check_value data_l3_semaine[32][35], "18:02"
      check_value data_l3_semaine[38][35], "18:10"
      
      check_value data_l3_semaine[76][3], "-"
      check_value data_l3_semaine[102][3], "7:25"
      check_value data_l3_semaine[76][41], "19:03"
      check_value data_l3_semaine[102][41], "19:30"
      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 3
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 8..38
      importer.stop_col = 1
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 13 ]
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 39 ]
      importer.add_exception Calendar::WEDNESDAY, [ 32..38, 27 ]
      importer.add_exception Calendar::WEDNESDAY, [ 32..38, 35 ]
      trips = importer.import(data_l3_semaine)
      
      import_stoptimes l3, data_l3_semaine[3][0], trips
      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 3
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 76..102
      importer.stop_col = 1
      check_value data_l3_semaine[76][13], "9:58"
      check_value data_l3_semaine[78][13], "10:00"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 76..78, 13 ]
      check_value data_l3_semaine[79][13], "10:00"
      importer.add_exception Calendar::WEDNESDAY, [ 79, 13 ]
      check_value data_l3_semaine[76][41], "19:03"
      check_value data_l3_semaine[78][41], "19:05"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 76..78, 41 ]
      check_value data_l3_semaine[79][41], "19:05"
      importer.add_exception Calendar::WEDNESDAY, [ 79, 41 ]
      check_value data_l3_semaine[76][27], "14:58"
      check_value data_l3_semaine[78][27], "15:00"
      importer.add_exception Calendar::WEDNESDAY, [ 76..78, 27 ]
      check_value data_l3_semaine[79][27], "15:00"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 79, 27 ]
      check_value data_l3_semaine[76][37], "18:08"
      check_value data_l3_semaine[78][37], "18:10"
      importer.add_exception Calendar::WEDNESDAY, [ 76..78, 37 ]
      check_value data_l3_semaine[79][37], "18:10"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 79, 37 ]
      
      trips = importer.import(data_l3_semaine)
      import_stoptimes l3, data_l3_semaine[71][0], trips
      
      
      data_l3_samedi = CSV.read('tmp/ligne_3_sept2011_samedi.csv', :encoding => 'UTF-8')
      
      check_value data_l3_samedi[6][3], "8:30"
      check_value data_l3_samedi[36][3], nil
      check_value data_l3_samedi[6][23], "18:35"
      check_value data_l3_samedi[36][23], nil
      
      check_value data_l3_samedi[67][3], "-"
      check_value data_l3_samedi[94][3], "8:28"
      check_value data_l3_samedi[67][25], "-"
      check_value data_l3_samedi[94][25], "19:30"
      
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 6..36
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l3_samedi)
      import_stoptimes l3, data_l3_samedi[2][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 67..94
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l3_samedi)
      import_stoptimes l3, data_l3_samedi[63][0], trips
      
      #####################################################################
      ###                           L1                                  ###
      #####################################################################
      mlog "Importing line 1"
      l1 = Line.create( :short_name => "1",
                        :long_name => "Saint-Lô-Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                        :short_long_name => "Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                        :fgcolor => '#ffffff',
                        :bgcolor => '#ff0000',
                        :src_id => '1',
                        :accessible => false,
                        :usage => :urban )
      data_l1_s1 = CSV.read('tmp/ligne_1_sept2011_sens1.csv', :encoding => 'UTF-8')
      data_l1_s2 = CSV.read('tmp/ligne_1_sept2011_sens2.csv', :encoding => 'UTF-8')
      
      check_value data_l1_s1[15][3], "7:01"
      check_value data_l1_s1[49][3], "7:31"
      check_value data_l1_s1[15][65], "-"
      check_value data_l1_s1[49][65], "20:03"
      
      check_value data_l1_s1[15][76], "-"
      check_value data_l1_s1[49][76], "8:38"
      check_value data_l1_s1[15][132], "-"
      check_value data_l1_s1[49][132], "20:03"
      
      
      check_value data_l1_s2[9][3], "6:30"
      check_value data_l1_s2[41][3], "7:01"
      check_value data_l1_s2[9][65], "19:00"
      check_value data_l1_s2[41][65], "-"
      
      check_value data_l1_s2[9][72], "7:31"
      check_value data_l1_s2[41][72], "-"
      check_value data_l1_s2[9][128], "19:00"
      check_value data_l1_s2[41][128], "-"
      
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 15..49
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l1_s1)
      import_stoptimes l1, data_l1_s1[6][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 15..49
      importer.stop_col = 1
      importer.first_trip_col = 76
      trips = importer.import(data_l1_s1)
      import_stoptimes l1, data_l1_s1[6][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 9..41
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l1_s2)
      import_stoptimes l1, data_l1_s2[3][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 9..41
      importer.stop_col = 1
      importer.first_trip_col = 72
      trips = importer.import(data_l1_s2)
      import_stoptimes l1, data_l1_s2[3][1], trips
      
      #####################################################################
      ###                           L2                                  ###
      #####################################################################
      mlog "Importing line 2"
      l2 = Line.create( :short_name => "2",
                        :long_name => "Saint-Lô-Conseil Général < > Saint-Lô-La Madeleine",
                        :short_long_name => "Conseil Général < > La Madeleine",
                        :fgcolor => '#ffffff',
                        :bgcolor => '#99ccff',
                        :src_id => '2',
                        :accessible => false,
                        :usage => :urban )
      data_l2_semaine = CSV.read('tmp/ligne_2_sept2011_semaine.csv', :encoding => 'UTF-8')
      data_l2_samedi = CSV.read('tmp/ligne_2_sept2011_samedi.csv', :encoding => 'UTF-8')
      
      check_value data_l2_semaine[9][3], "6:25"
      check_value data_l2_semaine[39][3], "6:56"
      check_value data_l2_semaine[9][43], "19:10"
      check_value data_l2_semaine[39][43], "19:41"
      
      check_value data_l2_semaine[73][3], "6:56"
      check_value data_l2_semaine[103][3], "7:25"
      check_value data_l2_semaine[73][43], "19:41"
      check_value data_l2_semaine[103][43], "20:10"
      
      
      check_value data_l2_samedi[6][3], "8:00"
      check_value data_l2_samedi[36][3], "8:31"
      check_value data_l2_samedi[6][23], "18:50"
      check_value data_l2_samedi[36][23], "19:21"
      
      check_value data_l2_samedi[70][3], "8:31"
      check_value data_l2_samedi[101][3], "9:03"
      check_value data_l2_samedi[70][23], "19:21"
      check_value data_l2_samedi[101][23], "19:50"
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 9..39
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_semaine)
      import_stoptimes l2, data_l2_semaine[4][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 6..39
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_samedi)
      import_stoptimes l2, data_l2_samedi[2][1], trips
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 73..103
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_semaine)
      import_stoptimes l2, data_l2_semaine[73][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 70..101
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_samedi)
      import_stoptimes l2, data_l2_samedi[65][1], trips
      
      mlog "Importing school lines"
      
      data_scolaires = CSV.read( 'tmp/scolaires_janv2011.csv', :encoding => 'UTF-8' )
      
      check_values data_scolaires, [
                                    # s1a
                                    [ 9, 1, "7:25" ],
                                    [ 35, 1, "7:50" ],
                                    # s1r
                                    [ 9, 5, "12:05" ],
                                    [ 35, 5, "12:32" ],
                                    # s2a
                                    [ 9, 9, "7:27" ],
                                    [ 28, 9, "7:52" ],
                                    # s2r
                                    [ 9, 13, "12:05" ],
                                    [ 28, 13, "12:30" ],
                                    # s3a
                                    [ 43, 1, "12:00" ],
                                    [ 54, 1, "12:18" ],
                                    # s4a
                                    [ 43, 5, "7:25" ],
                                    [ 62, 5, "7:50" ],
                                    # s5a
                                    [ 43, 9, "7:35" ],
                                    [ 59, 9, "7:50" ],
                                    # s5r
                                    [ 43, 13, "12:05" ],
                                    [ 59, 13, "12:20" ]
                                   ]
      
      
      ls = Line.create( :short_name => "S1",
                        :long_name => "Spécial Colombes / Pasteur / Bon Sauveur / Lavalley",
                        :short_long_name => "Spécial Colombes / Lavalley",
                        :fgcolor => '#ffffff',
                        :bgcolor => '#ff0000',
                        :src_id => 'SCL',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 1
      importer.stops_range = 9..35
      importer.stop_col = 0
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 9..35, 2 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Colombes - Lavalley", trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 5
      importer.stops_range = 9..35
      importer.stop_col = 4
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 9..35, 6 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Lavalley - Colombes", trips
      
      ls = Line.create( :short_name => "S2",
                        :long_name => "Spécial Agneaux / Lavalley",
                        :short_long_name => "Spécial Agneaux / Lavalley",
                        :fgcolor => '#000000',
                        :bgcolor => '#99ccff',
                        :src_id => 'SAL',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 9
      importer.stops_range = 9..28
      importer.stop_col = 8
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 9..28, 10 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Demeurance - Lavalley", trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 13
      importer.stops_range = 9..28
      importer.stop_col = 12
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 9..28, 14 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Lavalley - Demeurance", trips
      
      ls = Line.create( :short_name => "S3",
                        :long_name => "Spécial Bon Sauveur / Lavalley / St Georges Montcocq",
                        :short_long_name => "Spécial Bon Sauveur / Lavalley / St Georges Montcocq",
                        :fgcolor => '#000000',
                        :bgcolor => '#99cc00',
                        :src_id => 'SBSSGM',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 1
      importer.stops_range = 43..54
      importer.stop_col = 0
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 43..54, 2 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Collège Bechevel - St Georges", trips
      
      ls = Line.create( :short_name => "S4",
                        :long_name => "Spécial Agneaux / Le Verrier",
                        :short_long_name => "Spécial Agneaux / Le Verrier",
                        :fgcolor => '#ffffff',
                        :bgcolor => '#333399',
                        :src_id => 'SALV',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 5
      importer.stops_range = 43..62
      importer.stop_col = 4
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Agneaux - Le Verrier", trips


      ls = Line.create( :short_name => "S5",
                        :long_name => "Spécial Pasteur / Corot / Curie",
                        :short_long_name => "Spécial Pasteur / Corot / Curie",
                        :fgcolor => '#ffffff',
                        :bgcolor => '#cc99ff',
                        :src_id => 'SBSSGM',
                        :accessible => false,
                        :usage => :special )
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 9
      importer.stops_range = 43..59
      importer.stop_col = 8
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 43..59, 10 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Colombes - Lycée Curie Joliot", trips

      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.first_trip_col = 13
      importer.stops_range = 43..59
      importer.stop_col = 12
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 43..59, 14 ]
      trips = importer.import( data_scolaires )
      import_stoptimes ls, "Lycée Curie Joliot - Colombes", trips

      mlog "Importing KML file"

      xml = Nokogiri::XML( File.open( File.join( Rails.root, "tmp", "doc.kml" ) ) )
      xml.remove_namespaces!

      stops = []
      missings = []

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
            stop = Stop.where( "ts_rank_cd( '{0.1, 0.2, 0.4, 1.0}', to_tsvector('french',unaccent_string(name)), plainto_tsquery( 'french', ? ) ) > 0", qname ).first
          end
          if stop.nil?
            missings << name
          else
            stop.stop_aliases.create({ :src_id => src_id,
                                       :src_code => src_id,
                                       :src_name => name,
                                       :src_lat => coords[1],
                                       :src_lon => coords[0]
                                     })
            stops << stop
          end
        elsif not line_coord_elem.nil?
          line = Line.find_by_short_name elem.at_xpath("name").text.to_i.to_s
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
        points = stop.stop_aliases.where( 'src_lat is not null' ).collect do |sa|
          Point.from_lon_lat( sa.src_lon, sa.src_lat, 4326 )
        end
        collection = MultiPoint.from_points( points, 4326 )
        position = collection.envelope.center
        position.srid = 4326
        stop.geom = position
        stop.lat = position.lat
        stop.lon = position.lon
        stop.save
      end


      ActiveRecord::Base.transaction do
        Trip.all.each do |trip|
          next if trip.stop_times.empty?
          start = trip.stop_times.order(:arrival).first.stop
          stop = trip.stop_times.order(:arrival).last.stop
          next if start.geom.nil? or stop.geom.nil?
          bearing = start.geom.bearing( stop.geom )
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
      center_agency
    end
  end
end
