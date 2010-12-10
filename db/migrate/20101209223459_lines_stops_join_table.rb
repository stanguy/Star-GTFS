class LinesStopsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :lines_stops, :id => false do |t|
      t.integer :line_id
      t.integer :stop_id
    end
  end

  def self.down
    drop_table :lines_stops
  end
end
