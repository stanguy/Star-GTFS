# -*- coding: utf-8 -*-
require 'csv'
require 'st_lo_importer'
require 'stop_registry'

def mlog msg
  puts Time.now.to_s(:db) + " " + msg
end

def import_stoptimes line, headsign_str, trips
  headsign = Headsign.create( :name => headsign_str,
                              :line => line )
  trips.each do |mtrip|
    mtrip.each do |calendar,times|
      trip = Trip.create( :line => line, 
                          :calendar => calendar,
                          :headsign => headsign )
      times.each do |st|
        line.stops << st[:s]
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
end

stop_registry = StopRegistry.new


#####################################################################
###                           L3                                  ###
#####################################################################
mlog "Importing line 3"
l3 = Line.create( :short_name => "Ligne 3",
                  :long_name => "Saint-Lô-Bois Ardent / Centre Aquatique <> Saint-Georges-Montcocq-Mairie", 
                  :usage => :urban )

data_l3_semaine = CSV.read('tmp/ligne_3_janv2011_psvs_semaine.csv', :encoding => 'UTF-8')

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

import_stoptimes l3, data_l3_semaine[4][0], trips

importer = StLoImporter.new stop_registry
importer.first_trip_col = 3
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 79..103
importer.stop_col = 1
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 79..81, 17 ]
importer.add_exception Calendar::WEDNESDAY, [ 82, 17 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 79..81, 41 ]
importer.add_exception Calendar::WEDNESDAY, [ 82, 41 ]
importer.add_exception Calendar::WEDNESDAY, [ 79..81, 27 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 82, 27 ]
importer.add_exception Calendar::WEDNESDAY, [ 79..81, 37 ]
importer.add_exception Calendar::MONDAY|Calendar::TUESDAY|Calendar::THURSDAY|Calendar::FRIDAY, [ 82, 37 ]

trips = importer.import(data_l3_semaine)
import_stoptimes l3, data_l3_semaine[74][0], trips


data_l3_samedi = CSV.read('tmp/ligne_3_janv2011_psvs_samedi.csv', :encoding => 'UTF-8')
importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 6..37
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l3_samedi)
import_stoptimes l3, data_l3_semaine[2][0], trips

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 70..97
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l3_samedi)
import_stoptimes l3, data_l3_semaine[66][0], trips

#####################################################################
###                           L1                                  ###
#####################################################################
mlog "Importing line 1"
l1 = Line.create( :short_name => "Ligne 1",
                  :long_name => "Saint-Lô-Les Colombes <> Agneaux-Villechien / Centre Commercial La Demeurance", 
                  :usage => :urban )
data_l1_s1 = CSV.read('tmp/ligne_1_janv2011_psvs_s1.csv', :encoding => 'UTF-8')
data_l1_s2 = CSV.read('tmp/ligne_1_janv2011_psvs_s2.csv', :encoding => 'UTF-8')

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 15..51
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l1_s1)
import_stoptimes l1, data_l1_s1[6][1], trips

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 15..51
importer.stop_col = 73
importer.first_trip_col = 76
trips = importer.import(data_l1_s1)
import_stoptimes l1, data_l1_s1[6][1], trips


importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 9..43
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l1_s2)
import_stoptimes l1, data_l1_s2[3][1], trips

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 9..43
importer.stop_col = 69
importer.first_trip_col = 72
trips = importer.import(data_l1_s2)
import_stoptimes l1, data_l1_s2[3][1], trips

#####################################################################
###                           L2                                  ###
#####################################################################
mlog "Importing line 2"
l2 = Line.create( :short_name => "Ligne 2",
                  :long_name => "Saint-Lô-Conseil Général < > Saint-Lô-La Madeleine", 
                  :usage => :urban )
data_l2_semaine = CSV.read('tmp/ligne_2_janv2011_psvs_semaine.csv', :encoding => 'UTF-8')
data_l2_samedi = CSV.read('tmp/ligne_2_janv2011_psvs_samedi.csv', :encoding => 'UTF-8')


importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::WEEKDAY
importer.stops_range = 10..43
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
importer.stops_range = 77..110
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l2_semaine)
import_stoptimes l2, data_l2_semaine[73][1], trips

importer = StLoImporter.new stop_registry
importer.default_calendar = Calendar::SATURDAY
importer.stops_range = 73..106
importer.stop_col = 1
importer.first_trip_col = 3
trips = importer.import(data_l2_samedi)
import_stoptimes l2, data_l2_samedi[68][1], trips
