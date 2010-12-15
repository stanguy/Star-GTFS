class CreateTrips < ActiveRecord::Migration
  def self.up
    create_table :trips do |t|
      t.integer :line_id
      t.integer :src_id
      t.integer :calendar
      t.string :src_route_id
      t.integer :headsign_id
      t.integer :block_id

      t.timestamps
    end
  end

  def self.down
    drop_table :trips
  end
end
