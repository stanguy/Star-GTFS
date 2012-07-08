class CreateIncidents < ActiveRecord::Migration
  def change
    create_table :incidents do |t|
      t.integer :info_collector_id
      t.string :source_ref
      t.datetime :since
      t.datetime :expiration
      t.string :title
      t.text :detail

      t.timestamps
    end
    create_table :incidents_lines, :id => false do |t|
      t.integer :incident_id
      t.integer :line_id
    end
  end
end
