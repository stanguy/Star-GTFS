class AddSlugToStop < ActiveRecord::Migration
  def self.up
    add_column :stops, :slug, :string
  end

  def self.down
    remove_column :stops, :slug
  end
end
