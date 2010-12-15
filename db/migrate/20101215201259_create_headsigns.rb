class CreateHeadsigns < ActiveRecord::Migration
  def self.up
    create_table :headsigns do |t|
      t.string :name
      t.integer :line_id

      t.timestamps
    end
  end

  def self.down
    drop_table :headsigns
  end
end
