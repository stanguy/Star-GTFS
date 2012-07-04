class CreateStopTimes < ActiveRecord::Migration
  def self.up
    create_table :stop_times, :id => false do |t|
      t.integer :stop_id
      t.integer :line_id
      t.integer :trip_id
      t.integer :headsign_id
      t.integer :arrival
      t.integer :departure
      t.integer :calendar
    end
  end

  def self.down
    drop_table :stop_times
  end
end
