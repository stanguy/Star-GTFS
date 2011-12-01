#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'gmap_polyline_encoder'

xml = Nokogiri::XML( File.open( File.join( Rails.root, "tmp", "reseau_star.kml" ) ) )
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
    puts "points: " + data.count.to_s
    encoder = GMapPolylineEncoder.new( :reduce => true, :zoomlevel => 13, :escape => false )
    path = encoder.encode( data )
#    puts path.to_s
    line.polylines.create( :path => path[:points] )
  end
end
