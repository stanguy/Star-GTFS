class CreateStopAliases < ActiveRecord::Migration
  def self.up
    create_table :stop_aliases do |t|
      t.integer :stop_id
      t.string :src_id
      t.string :src_code
      t.string :src_name
      t.float :src_lat
      t.float :src_lon

      t.timestamps
    end
  end

  def self.down
    drop_table :stop_aliases
  end
end
