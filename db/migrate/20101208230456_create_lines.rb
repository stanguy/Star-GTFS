class CreateLines < ActiveRecord::Migration
  def self.up
    create_table :lines do |t|
      t.string :src_id
      t.string :short_name
      t.string :long_name
      t.string :bgcolor
      t.string :fgcolor

      t.timestamps
    end
  end

  def self.down
    drop_table :lines
  end
end
