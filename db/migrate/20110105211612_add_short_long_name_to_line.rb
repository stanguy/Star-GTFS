class AddShortLongNameToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :short_long_name, :string
  end

  def self.down
    remove_column :lines, :short_long_name
  end
end
