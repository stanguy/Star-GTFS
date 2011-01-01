class AddLineCacheToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :line_ids_cache, :string
  end

  def self.down
    remove_column :stops, :line_ids_cache
  end
end
