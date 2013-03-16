class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.string :src_id
      t.integer :days
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
