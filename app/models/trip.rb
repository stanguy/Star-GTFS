class Trip < ActiveRecord::Base
  belongs_to :line
  belongs_to :headsign

  has_many :stop_times, :dependent => :delete_all

  scope :of_the_day, lambda {
    of_week_day( Calendar.from_time( Time.zone.now ) )
  }
  scope :of_week_day, lambda {|d|
    where( "calendar & ? > 0", d )
  }
end
