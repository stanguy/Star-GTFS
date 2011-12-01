class CreatePolylines < ActiveRecord::Migration
  def change
    create_table :polylines do |t|
      t.integer :line_id
      t.text :path

      t.timestamps
    end
  end
end
