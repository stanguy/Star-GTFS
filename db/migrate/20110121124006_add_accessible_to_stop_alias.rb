class AddAccessibleToStopAlias < ActiveRecord::Migration
  def self.up
    add_column :stop_aliases, :accessible, :boolean
  end

  def self.down
    remove_column :stop_aliases, :accessible
  end
end
