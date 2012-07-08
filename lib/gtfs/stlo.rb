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
      headsign = Headsign.find_or_create_by_name_and_line_id( fix_stlo_headsign(headsign_str),
                                                              line.id )
      headsign.save
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
                               :publisher => "Veolia Transdev",
                               :feed_ref => "20111103",
                               :tz => "Europe/Paris",
                               :lang => :fr,
                               :city => "Saint Lô",
                               :ads_allowed => false )

      
      stop_registry = StopRegistry.new @agency
      
      #####################################################################
      ###                           L3                                  ###
      #####################################################################
      mlog "Importing line 3"
      l3 = Line.create( :short_name => "3",
                        :agency_id => @agency.id,
                        :long_name => "Saint-Lô-Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie",
                        :short_long_name => "Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie",
                        :fgcolor => '000000',
                        :bgcolor => 'ccffcc',
                        :src_id => "3",
                        :accessible => false,
                        :usage => :urban )
      
      data_l3_semaine = CSV.read( File.join( self.root, 'ligne 3_ ete2012 %28avec sncf%29 - LR3.csv' ), :encoding => 'UTF-8')
      check_value data_l3_semaine[8][3], "6:55"
      check_value data_l3_semaine[38][3], "-"
      check_value data_l3_semaine[8][27], "19:25"
      check_value data_l3_semaine[38][27], "-"
      
      check_value data_l3_semaine[71][3], "-"
      check_value data_l3_semaine[97][3], "7:47"
      check_value data_l3_semaine[71][25], "18:51"
      check_value data_l3_semaine[97][25], "19:16"
      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 3
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 8..38
      importer.stop_col = 1
      trips = importer.import(data_l3_semaine)
      
      import_stoptimes l3, data_l3_semaine[3][0], trips
      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 3
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 71..97
      importer.stop_col = 1
      
      trips = importer.import(data_l3_semaine)
      import_stoptimes l3, data_l3_semaine[66][0], trips
      
      
      data_l3_samedi = CSV.read( File.join( self.root, 'ligne 3_ ete2012 %28avec sncf%29 - LR3_Samedi.csv' ), :encoding => 'UTF-8')
      
      check_value data_l3_samedi[6][3], "8:15"
      check_value data_l3_samedi[36][3], nil
      check_value data_l3_samedi[6][25], "19:15"
      check_value data_l3_samedi[36][25], "-"
      
      check_value data_l3_samedi[65][3], "-"
      check_value data_l3_samedi[91][3], "8:07"
      check_value data_l3_samedi[65][25], "18:41"
      check_value data_l3_samedi[91][25], "19:07"
      
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 6..36
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l3_samedi)
      import_stoptimes l3, data_l3_samedi[2][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 65..91
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l3_samedi)
      import_stoptimes l3, data_l3_samedi[61][0], trips
      
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

      data_l1_s1 = CSV.read( File.join( self.root, 'ligne 1_ ete2012 %28avec sncf%29 - Sens 1.csv' ), :encoding => 'UTF-8')
      data_l1_s2 = CSV.read( File.join( self.root, 'ligne 1_ ete2012 %28avec sncf%29 - Sens 2.csv' ), :encoding => 'UTF-8')
      
      check_value data_l1_s1[10][3], "-"
      check_value data_l1_s1[44][3], "7:18"
      check_value data_l1_s1[10][41], "19:35"
      check_value data_l1_s1[44][41], "20:05"
      
      check_value data_l1_s1[10][47], "-"
      check_value data_l1_s1[44][47], "8:18"
      check_value data_l1_s1[10][81], "19:35"
      check_value data_l1_s1[44][81], "20:05"
      
      
      check_value data_l1_s2[7][3], "6:20"
      check_value data_l1_s2[39][3], "-"
      check_value data_l1_s2[7][41], "19:00"
      check_value data_l1_s2[39][41], "19:31"
      
      check_value data_l1_s2[7][47], "7:20"
      check_value data_l1_s2[39][47], "-"
      check_value data_l1_s2[7][81], "19:00"
      check_value data_l1_s2[39][81], "19:31"
      
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 10..44
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l1_s1)
      import_stoptimes l1, data_l1_s1[6][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 10..44
      importer.stop_col = 1
      importer.first_trip_col = 47
      trips = importer.import(data_l1_s1)
      import_stoptimes l1, data_l1_s1[6][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 7..39
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l1_s2)
      import_stoptimes l1, data_l1_s2[3][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 7..39
      importer.stop_col = 1
      importer.first_trip_col = 47
      trips = importer.import(data_l1_s2)
      import_stoptimes l1, data_l1_s2[3][1], trips
      
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
      data_l2_semaine = CSV.read( File.join( self.root, 'ligne 2_ ete2012 %28avec sncf%29 - LR2 ETE 2011.csv' ), :encoding => 'UTF-8')
      data_l2_samedi  = CSV.read( File.join( self.root, 'ligne 2_ ete2012 %28avec sncf%29 - LR2 SAMEDI ETE 2011.csv' ), :encoding => 'UTF-8')
      
      check_value data_l2_semaine[9][3], "7:20"
      check_value data_l2_semaine[39][3], "7:43"
      check_value data_l2_semaine[9][25], "19:15"
      check_value data_l2_semaine[39][25], "19:38"
      
      check_value data_l2_semaine[71][3], "7:45"
      check_value data_l2_semaine[102][3], "8:11"
      check_value data_l2_semaine[71][25], "19:40"
      check_value data_l2_semaine[102][25], "20:06"
      
      
      check_value data_l2_samedi[6][3], "8:20"
      check_value data_l2_samedi[36][3], "8:44"
      check_value data_l2_samedi[6][23], "19:10"
      check_value data_l2_samedi[36][23], "19:34"
      
      check_value data_l2_samedi[66][3], "8:50"
      check_value data_l2_samedi[97][3], "9:16"
      check_value data_l2_samedi[66][23], "19:40"
      check_value data_l2_samedi[97][23], "20:06"
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 9..39
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_semaine)
      import_stoptimes l2, data_l2_semaine[4][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 6..36
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_samedi)
      import_stoptimes l2, data_l2_samedi[2][1], trips
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 71..102
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_semaine)
      import_stoptimes l2, data_l2_semaine[67][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 66..97
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_samedi)
      import_stoptimes l2, data_l2_samedi[61][1], trips
      
      if false
      mlog "Importing school lines"
      
      data_scolaires = CSV.read( File.join( self.root, 'scolaires_janv2011.csv' ), :encoding => 'UTF-8' )
      
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
                        :agency_id => @agency.id,
                        :long_name => "Spécial Colombes / Pasteur / Bon Sauveur / Lavalley",
                        :short_long_name => "Spécial Colombes / Lavalley",
                        :fgcolor => 'ffffff',
                        :bgcolor => 'ff0000',
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
                        :agency_id => @agency.id,
                        :long_name => "Spécial Agneaux / Lavalley",
                        :short_long_name => "Spécial Agneaux / Lavalley",
                        :fgcolor => '000000',
                        :bgcolor => '99ccff',
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
                        :agency_id => @agency.id,
                        :long_name => "Spécial Bon Sauveur / Lavalley / St Georges Montcocq",
                        :short_long_name => "Spécial Bon Sauveur / Lavalley / St Georges Montcocq",
                        :fgcolor => '000000',
                        :bgcolor => '99cc00',
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
                        :agency_id => @agency.id,
                        :long_name => "Spécial Agneaux / Le Verrier",
                        :short_long_name => "Spécial Agneaux / Le Verrier",
                        :fgcolor => 'ffffff',
                        :bgcolor => '333399',
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
                        :agency_id => @agency.id,
                        :long_name => "Spécial Pasteur / Corot / Curie",
                        :short_long_name => "Spécial Pasteur / Corot / Curie",
                        :fgcolor => 'ffffff',
                        :bgcolor => 'cc99ff',
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
      end

      mlog "Importing KML file"

      xml = Nokogiri::XML( File.open( File.join( self.root, "doc.kml" ) ) )
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
