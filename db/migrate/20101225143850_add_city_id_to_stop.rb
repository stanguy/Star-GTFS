class AddCityIdToStop < ActiveRecord::Migration
  def self.up
    add_column :stops, :city_id, :integer
  end

  def self.down
    remove_column :stops, :city_id
  end
end
