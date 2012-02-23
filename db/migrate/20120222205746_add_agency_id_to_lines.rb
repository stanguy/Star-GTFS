class AddAgencyIdToLines < ActiveRecord::Migration
  def change
    add_column :lines, :agency_id, :int
    add_index :lines, :agency_id
  end
end
