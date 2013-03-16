class AddCalendarRefs < ActiveRecord::Migration
  def up
    remove_column :trips, :calendar
    add_column :trips, :calendar_id, :integer
    remove_column :stop_times, :calendar
    add_column :stop_times, :calendar_id, :integer
  end

  def down
    remove_column :trips, :calendar_id
    add_column :trips, :calendar, :integer
    remove_column :stop_times, :calendar_id
    add_column :stop_times, :calendar, :integer
  end
end
