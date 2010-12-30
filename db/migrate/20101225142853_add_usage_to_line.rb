class AddUsageToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :usage, :string
  end

  def self.down
    remove_column :lines, :usage
  end
end
