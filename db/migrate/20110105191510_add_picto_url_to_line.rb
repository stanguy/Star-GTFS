class AddPictoUrlToLine < ActiveRecord::Migration
  def self.up
    add_column :lines, :picto_url, :string
  end

  def self.down
    remove_column :lines, :picto_url
  end
end
