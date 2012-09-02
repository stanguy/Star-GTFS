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
        raise "Empty headsign at #{caller(1)[0]}"
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
    def check_value cell, expected, skip = 0
      unless cell.to_s.strip == expected
        raise "Assertion failed: '#{cell.to_s}' != '#{expected.to_s}' at #{caller(1)[skip]}" 
      end
    end
    
    def check_values dataset, checks
      checks.each do |c|
        x, y, v = c
        check_value dataset[x][y], v, 3
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
                        :long_name => "Saint-Lô-Bois Ardent / Grandin <> Saint-Georges-Montcocq",
                        :short_long_name => "Bois Ardent / Grandin <> Saint-Georges-Montcocq",
                        :fgcolor => '000000',
                        :bgcolor => 'ccffcc',
                        :src_id => "3",
                        :accessible => false,
                        :usage => :urban )
      
      data_l3_semaine = CSV.read( File.join( self.root, 'ligne 3_ hiv12-13 v2 - LR3.csv' ), :encoding => 'UTF-8')
      check_value data_l3_semaine[8][3], "7:00"
      check_value data_l3_semaine[38][3], "|"
      check_value data_l3_semaine[8][22], "19:10"
      check_value data_l3_semaine[38][22], "|"
      
      # exceptions 
      # Mon/Tue/Thu/Fri
      check_value data_l3_semaine[32][8], "09:53"
      check_value data_l3_semaine[38][8], "10:00"
      check_value data_l3_semaine[32][10], "12:03"
      check_value data_l3_semaine[38][10], "12:10"
      check_value data_l3_semaine[32][21], "19:08"
      check_value data_l3_semaine[38][21], "19:15"
      # Wed
      check_value data_l3_semaine[32][15], "14:53"
      check_value data_l3_semaine[38][15], "15:00"
      check_value data_l3_semaine[32][19], "18:13"
      check_value data_l3_semaine[38][19], "18:20"


      # return
      check_value data_l3_semaine[74][3], "|"
      check_value data_l3_semaine[100][3], "7:22"
      check_value data_l3_semaine[74][22], "19:13"
      check_value data_l3_semaine[100][22], "19:38"
      # exceptions 
      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 3
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 8..38
      importer.stop_col = 1
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 8 ]
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 10 ]
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 21 ]
      importer.add_exception Calendar::WEDNESDAY, [ 32..38, 15 ]
      importer.add_exception Calendar::WEDNESDAY, [ 32..38, 19 ]
      trips = importer.import(data_l3_semaine)
      
      import_stoptimes l3, data_l3_semaine[3][0], trips
      
      
      importer = StLoImporter.new stop_registry
      importer.first_trip_col = 3
      importer.default_calendar = Calendar::WEEKDAY
      importer.stops_range = 74..100
      importer.stop_col = 1
      check_value data_l3_semaine[74][8], "9:58"
      check_value data_l3_semaine[76][8], "10:00"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 74..76, 8 ]
      check_value data_l3_semaine[77][8], "10:00"
      importer.add_exception Calendar::WEDNESDAY, [ 77, 8 ]
      check_value data_l3_semaine[74][10], "12:08"
      check_value data_l3_semaine[76][10], "12:10"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 74..76, 10 ]
      check_value data_l3_semaine[77][10], "12:10"
      importer.add_exception Calendar::WEDNESDAY, [ 77, 10 ]
      check_value data_l3_semaine[74][15], "14:58"
      check_value data_l3_semaine[76][15], "15:00"
      importer.add_exception Calendar::WEDNESDAY, [ 74..76, 15 ]
      check_value data_l3_semaine[77][15], "15:00"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 77, 15 ]
      check_value data_l3_semaine[74][20], "18:18"
      check_value data_l3_semaine[76][20], "18:20"
      importer.add_exception Calendar::WEDNESDAY, [ 74..76, 20 ]
      check_value data_l3_semaine[77][20], "18:20"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 77, 20 ]      
      check_value data_l3_semaine[74][22], "19:13"
      check_value data_l3_semaine[76][22], "19:15"
      importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 74..76, 22 ]
      check_value data_l3_semaine[77][22], "19:15"
      importer.add_exception Calendar::WEDNESDAY, [ 77, 22 ]
      trips = importer.import(data_l3_semaine)
      import_stoptimes l3, data_l3_semaine[69][0], trips
      
      data_l3_samedi = CSV.read( File.join( self.root, 'ligne 3_ hiv12-13 v2 - LR3_Samedi.csv' ), :encoding => 'UTF-8')
      
      check_value data_l3_samedi[6][3], "8:30"
      check_value data_l3_samedi[37][3], ''
      check_value data_l3_samedi[6][13], "18:40"
      check_value data_l3_samedi[36][13], ''
      
      check_value data_l3_samedi[65][3], ""
      check_value data_l3_samedi[90][3], "8:22"
      check_value data_l3_samedi[65][14], ""
      check_value data_l3_samedi[90][14], "19:27"
      
      
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 6..36
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l3_samedi)
      import_stoptimes l3, data_l3_samedi[2][0], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 65..90
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l3_samedi)
      import_stoptimes l3, data_l3_samedi[60][0], trips      
      
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

      data_l1_s1 = CSV.read( File.join( self.root, 'ligne 1_ hiv12-13 v2 - Sens 1.csv' ), :encoding => 'UTF-8')
      data_l1_s2 = CSV.read( File.join( self.root, 'ligne 1_ hiv12-13 v2 - Sens 2.csv' ), :encoding => 'UTF-8')
      
      check_value data_l1_s1[10][3], "6:59"
      check_value data_l1_s1[45][3], "7:28"
      check_value data_l1_s1[10][33], "|"
      check_value data_l1_s1[45][33], "19:58"
      
      check_value data_l1_s1[10][39], "|"
      check_value data_l1_s1[45][39], "8:40"
      check_value data_l1_s1[10][60], "19:35"
      check_value data_l1_s1[45][60], "20:08"
      
      
      check_value data_l1_s2[7][3], "6:30"
      check_value data_l1_s2[39][3], "|"
      check_value data_l1_s2[7][33], "19:05"
      check_value data_l1_s2[39][33], "19:32"
      
      check_value data_l1_s2[7][39], "7:38"
      check_value data_l1_s2[39][39], "8:05"
      check_value data_l1_s2[7][60], "19:05"
      check_value data_l1_s2[39][60], "|"
      
      
      
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

      data_l2_semaine = CSV.read( File.join( self.root, 'ligne 2_ hiv12-13 v2 - LR2 hiv 2013.csv' ), :encoding => 'UTF-8')
      data_l2_samedi  = CSV.read( File.join( self.root, 'ligne 2_ hiv12-13 v2 - LR2 SAMEDI hiver 2013.csv' ), :encoding => 'UTF-8')
      
      check_value data_l2_semaine[9][3], "6:25"
      check_value data_l2_semaine[39][3], "6:54"
      check_value data_l2_semaine[9][23], "19:10"
      check_value data_l2_semaine[39][23], "19:39"
      
      check_value data_l2_semaine[67][3], "6:56"
      check_value data_l2_semaine[98][3], "7:24"
      check_value data_l2_semaine[67][23], "19:41"
      check_value data_l2_semaine[98][23], "20:09"
      
      
      check_value data_l2_samedi[6][3], "8:00"
      check_value data_l2_samedi[36][3], "8:29"
      check_value data_l2_samedi[6][13], "18:50"
      check_value data_l2_samedi[36][13], "19:19"
      
      check_value data_l2_samedi[62][3], "8:32"
      check_value data_l2_samedi[93][3], "9:00"
      check_value data_l2_samedi[62][13], "19:22"
      check_value data_l2_samedi[93][13], "19:50"
      
      
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
      importer.stops_range = 67..98
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_semaine)
      import_stoptimes l2, data_l2_semaine[63][1], trips
      
      importer = StLoImporter.new stop_registry
      importer.default_calendar = Calendar::SATURDAY
      importer.stops_range = 62..93
      importer.stop_col = 1
      importer.first_trip_col = 3
      trips = importer.import(data_l2_samedi)

      import_stoptimes l2, data_l2_samedi[58][1], trips
      
      if true
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
