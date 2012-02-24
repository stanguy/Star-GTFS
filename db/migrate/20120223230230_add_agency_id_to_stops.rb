class AddAgencyIdToStops < ActiveRecord::Migration
  def change
    add_column :stops, :agency_id, :int

  end
end
