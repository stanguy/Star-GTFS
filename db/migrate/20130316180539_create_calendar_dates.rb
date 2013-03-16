class CreateCalendarDates < ActiveRecord::Migration
  def change
    create_table :calendar_dates do |t|
      t.integer :calendar_id
      t.date :exception_date
      t.boolean :exclusion

    end
  end
end
