class Trip < ActiveRecord::Base
  belongs_to :line
  belongs_to :headsign

  scope :of_the_day, lambda {
    where( "calendar & ? > 0", Calendar.from_time( Time.zone.now ) )
  }
end
