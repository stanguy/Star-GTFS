class Trip < ActiveRecord::Base
  belongs_to :line

  scope :of_the_day, lambda {
    where( "calendar & ? > 0", Calendar.from_time( Time.now ) )
  }
end
