class UpdatePointsForAdapter < ActiveRecord::Migration
  def up
    [ 'stops', 'pos', 'bike_stations', 'metro_stations' ].each do |table|
      remove_column table, :geom
      add_column table, :geom, :point, :srid => 4326, :geographic => true
    end
    %w{ lines agencies }.each do |table|
      remove_column table, :center
      add_column table, :center, :point, :srid => 4326, :geographic => true
    end
    remove_column :agencies, :bbox
    add_column :agencies, :bbox, :multi_point, :srid => 4326, :geographic => true
    add_column :stop_aliases, :geom, :point, :srid => 4326, :geographic => true
  end

  def down
    remove_column :stop_aliases, :geom
  end
end
