class CreateInfoCollectors < ActiveRecord::Migration
  def change
    create_table :info_collectors do |t|
      t.string :type
      t.datetime :last_called_at
      t.text :params
      t.integer :agency_id

      t.timestamps
    end
  end
end
