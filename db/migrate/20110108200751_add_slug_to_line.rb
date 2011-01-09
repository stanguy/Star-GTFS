class AddSlugToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :slug, :string
  end

  def self.down
    remove_column :lines, :slug
  end
end
