class AddAccessibleToStop < ActiveRecord::Migration
  def self.up
    add_column :stops, :accessible, :boolean
  end

  def self.down
    remove_column :stops, :accessible
  end
end
