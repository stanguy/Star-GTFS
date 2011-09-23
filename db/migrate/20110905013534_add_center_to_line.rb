class AddCenterToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :center, :point, :srid => 4326, :with_z => false
  end

  def self.down
    remove_column :lines, :center
  end
end
