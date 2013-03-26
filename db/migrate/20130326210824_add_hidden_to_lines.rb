class AddHiddenToLines < ActiveRecord::Migration
  def change
    add_column :lines, :hidden, :boolean, :default => false
  end
end
