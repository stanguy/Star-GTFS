class AddOldSrcIdToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :old_src_id, :string
  end

  def self.down
    remove_column :lines, :old_src_id
  end
end
