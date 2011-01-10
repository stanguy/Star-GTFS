class AddSlugToHeadsign < ActiveRecord::Migration
  def self.up
    add_column :headsigns, :slug, :string
  end

  def self.down
    remove_column :headsigns, :slug
  end
end
