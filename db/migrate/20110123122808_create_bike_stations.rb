class CreateBikeStations < ActiveRecord::Migration
  def self.up
    create_table :bike_stations do |t|
      t.integer :number
      t.string :name
      t.string :address
      t.float :lat
      t.float :lon
      t.boolean :pos

      t.timestamps
    end
  end

  def self.down
    drop_table :bike_stations
  end
end
