class CreateTrips < ActiveRecord::Migration
  def self.up
    create_table :trips do |t|
      t.integer :src_id
      t.integer :calendar
      t.string :src_route_id
      t.string :headsign
      t.integer :block_id

      t.timestamps
    end
  end

  def self.down
    drop_table :trips
  end
end
