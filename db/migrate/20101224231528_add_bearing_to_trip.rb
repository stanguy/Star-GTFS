class AddBearingToTrip < ActiveRecord::Migration
  def self.up
    add_column :trips, :bearing, :string
  end

  def self.down
    remove_column :trips, :bearing
  end
end
