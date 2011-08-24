# -*- coding: utf-8 -*-
require 'csv'
require 'st_lo_importer'
require 'stop_registry'

def mlog msg
  puts Time.now.to_s(:db) + " " + msg
end

def import_stoptimes line, headsign_str, trips
  if headsign_str.blank?
    raise "Empty headsign"
  end
  headsign = Headsign.create( :name => headsign_str,
                              :line => line )
  line_stops = []
  trips.each do |mtrip|
    mtrip.each do |calendar,times|
      trip = Trip.create( :line => line, 
                          :calendar => calendar,
                          :headsign => headsign )
      times.each do |st|
        line_stops << st[:s]
        StopTime.create( :stop => st[:s],
                         :line => line,
                         :trip => trip,
                         :headsign => headsign,
                         :arrival => st[:t],
                         :departure => st[:t],
                         :calendar => calendar )
      end
    end
  end
  line.stops = line_stops.uniq
end
def check_value cell, expected
  unless cell == expected
    puts "'#{cell.to_s}' != '#{expected.to_s}'"
    raise "Assertion failed" 
  end
end
    

stop_registry = StopRegistry.new

#####################################################################
###                           L3                                  ###
#####################################################################
mlog "Importing line 3"
l3 = Line.create( :short_name => "Ligne 3",
                  :long_name => "Saint-Lô-Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie",
                  :short_long_name => "Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie",
                  :fgcolor => '#ffffff',
                  :bgcolor => '#B1CB44',
                  :src_id => "3",
                  :accessible => false,
                  :usage => :urban )

data_l3_semaine = CSV.read('tmp/ligne_3_ete2011_semaine.csv', :encoding => 'UTF-8')
check_value data_l3_semaine[8][3], "6:55"
check_value data_l3_semaine[38][3], "-"
check_value data_l3_semaine[8][27], "19:25"
check_value data_l3_semaine[38][27], "-"

check_value data_l3_semaine[73][3], "-"
check_value data_l3_semaine[99][3], "7:53"
check_value data_l3_semaine[73][25], "18:53"
check_value data_l3_semaine[99][25], "19:20"


importer = StLoImporter.new stop_registry
importer.first_trip_col = 3
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 8..38
importer.stop_col = 1
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 17 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 32..38, 39 ]
importer.add_exception Calendar::WEDNESDAY, [ 32..38, 27 ]
importer.add_exception Calendar::WEDNESDAY, [ 32..38, 35 ]
trips = importer.import(data_l3_semaine)

import_stoptimes l3, data_l3_semaine[3][0], trips

importer = StLoImporter.new stop_registry
importer.first_trip_col = 3
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 73..99
importer.stop_col = 1
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 76..79, 17 ]
importer.add_exception Calendar::WEDNESDAY, [ 80, 17 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 76..79, 41 ]
importer.add_exception Calendar::WEDNESDAY, [ 80, 41 ]
importer.add_exception Calendar::WEDNESDAY, [ 76..79, 27 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 80, 27 ]
importer.add_exception Calendar::WEDNESDAY, [ 76..79, 37 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 80, 37 ]

trips = importer.import(data_l3_semaine)
import_stoptimes l3, data_l3_semaine[68][0], trips


data_l3_samedi = CSV.read('tmp/ligne_3_ete2011_samedi.csv', :encoding => 'UTF-8')

check_value data_l3_samedi[6][3], "8:15"
check_value data_l3_samedi[36][3], nil
check_value data_l3_samedi[6][25], "19:15"
check_value data_l3_samedi[36][25], "-"

check_value data_l3_samedi[67][3], "-"
check_value data_l3_samedi[93][3], "8:13"
check_value data_l3_samedi[67][25], "18:43"
check_value data_l3_samedi[93][25], "19:10"



importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 6..36
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l3_samedi)
import_stoptimes l3, data_l3_samedi[2][0], trips

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 67..93
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l3_samedi)
import_stoptimes l3, data_l3_samedi[63][0], trips

#####################################################################
###                           L1                                  ###
#####################################################################
mlog "Importing line 1"
l1 = Line.create( :short_name => "Ligne 1",
                  :long_name => "Saint-Lô-Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                  :short_long_name => "Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                  :fgcolor => '#ffffff',
                  :bgcolor => '#C8012A',
                  :src_id => '1',
                  :accessible => false,
                  :usage => :urban )
data_l1_s1 = CSV.read('tmp/ligne_1_ete2011_sens1.csv', :encoding => 'UTF-8')
data_l1_s2 = CSV.read('tmp/ligne_1_ete2011_sens2.csv', :encoding => 'UTF-8')

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
importer.stop_col = 39
importer.first_trip_col = 41
trips = importer.import(data_l1_s1)
import_stoptimes l1, data_l1_s1[6][1], trips


importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 7..44
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l1_s2)
import_stoptimes l1, data_l1_s2[3][1], trips

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 7..44
importer.stop_col = 45
importer.first_trip_col = 47
trips = importer.import(data_l1_s2)
import_stoptimes l1, data_l1_s2[3][1], trips

#####################################################################
###                           L2                                  ###
#####################################################################
mlog "Importing line 2"
l2 = Line.create( :short_name => "Ligne 2",
                  :long_name => "Saint-Lô-Conseil Général < > Saint-Lô-La Madeleine",
                  :short_long_name => "Conseil Général < > La Madeleine",
                  :fgcolor => '#ffffff',
                  :bgcolor => '#006ab4',
                  :src_id => '2',
                  :accessible => false,
                  :usage => :urban )
data_l2_semaine = CSV.read('tmp/ligne_2_ete2011_semaine.csv', :encoding => 'UTF-8')
data_l2_samedi = CSV.read('tmp/ligne_2_ete2011_samedi.csv', :encoding => 'UTF-8')

check_value data_l2_semaine[9][3], "7:15"
check_value data_l2_semaine[39][3], "7:45"
check_value data_l2_semaine[9][25], "19:10"
check_value data_l2_semaine[39][25], "19:40"

check_value data_l2_semaine[73][3], "7:45"
check_value data_l2_semaine[103][3], "8:17"
check_value data_l2_semaine[73][25], "19:40"
check_value data_l2_semaine[103][25], "20:09"


check_value data_l2_samedi[6][3], "8:20"
check_value data_l2_samedi[36][3], "8:50"
check_value data_l2_samedi[6][23], "19:10"
check_value data_l2_samedi[36][23], "19:40"

check_value data_l2_samedi[70][3], "8:50"
check_value data_l2_samedi[101][3], "9:22"
check_value data_l2_samedi[70][23], "19:40"
check_value data_l2_samedi[101][23], "20:09"


importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 9..36
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

