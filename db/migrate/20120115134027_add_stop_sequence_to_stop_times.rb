class AddStopSequenceToStopTimes < ActiveRecord::Migration
  def change
    add_column :stop_times, :stop_sequence, :int
  end
end
