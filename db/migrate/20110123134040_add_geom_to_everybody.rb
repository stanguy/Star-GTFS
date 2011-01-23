class AddGeomToEverybody < ActiveRecord::Migration
  def self.up
    [ 'stops', 'pos', 'bike_stations', 'metro_stations' ].each do |table|
      add_column table, :geom, :point, :srid => 4326, :with_z => false
    end
  end

  def self.down
    [ 'stops', 'pos', 'bike_stations', 'metro_stations' ].each do |table|
      remove_column table, :geom
    end
  end
end
