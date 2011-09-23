class AddOldSrcIdToStopAlias < ActiveRecord::Migration
  def self.up
    add_column :stop_aliases, :old_src_id, :string
  end

  def self.down
    remove_column :stop_aliases, :old_src_id
  end
end
