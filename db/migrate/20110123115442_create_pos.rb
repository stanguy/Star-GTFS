class CreatePos < ActiveRecord::Migration
  def self.up
    create_table :pos do |t|
      t.string :name
      t.string :type
      t.text :address
      t.string :zipcode
      t.string :city
      t.string :schedule
      t.float :lat
      t.float :lon

      t.timestamps
    end
  end

  def self.down
    drop_table :pos
  end
end
