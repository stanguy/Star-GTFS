class CreateMetroStations < ActiveRecord::Migration
  def self.up
    create_table :metro_stations do |t|
      t.string :src_id
      t.string :name
      t.string :address
      t.float :lat
      t.float :lon

      t.timestamps
    end
  end

  def self.down
    drop_table :metro_stations
  end
end
