# -*- coding: utf-8 -*-
require 'csv'
require 'st_lo_importer'
require 'stop_registry'

def mlog msg
  puts Time.now.to_s(:db) + " " + msg
end

def fix_stlo_headsign headsign
  headsign.split(/ (è|=>) /).pop
end
    

def import_stoptimes line, headsign_str, trips
  if headsign_str.blank? || headsign_str.nil?
    raise "Empty headsign"
  end
  headsign = Headsign.create( :name => fix_stlo_headsign(headsign_str),
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
l1 = Line.create( :short_name => "Ligne 1",
                  :long_name => "Saint-Lô-Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                  :short_long_name => "Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance",
                  :fgcolor => '#ffffff',
                  :bgcolor => '#C8012A',
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
l2 = Line.create( :short_name => "Ligne 2",
                  :long_name => "Saint-Lô-Conseil Général < > Saint-Lô-La Madeleine",
                  :short_long_name => "Conseil Général < > La Madeleine",
                  :fgcolor => '#ffffff',
                  :bgcolor => '#006ab4',
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

