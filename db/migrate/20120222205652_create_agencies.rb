class CreateAgencies < ActiveRecord::Migration
  def change
    create_table :agencies do |t|
      t.string :name
      t.string :url
      t.string :tz
      t.string :phone
      t.string :lang
      t.string :city
      t.boolean :ads_allowed
      t.multi_point :bbox, :srid => 4326, :with_z => false
      t.point :center, :srid => 4326, :with_z => false

      t.timestamps
    end
  end
end
