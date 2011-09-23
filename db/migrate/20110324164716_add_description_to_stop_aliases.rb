class AddDescriptionToStopAliases < ActiveRecord::Migration
  def self.up
    add_column :stop_aliases, :description, :string
  end

  def self.down
    remove_column :stop_aliases, :description
  end
end
