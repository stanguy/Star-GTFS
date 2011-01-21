class AddAccessibleToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :accessible, :boolean
  end

  def self.down
    remove_column :lines, :accessible
  end
end
