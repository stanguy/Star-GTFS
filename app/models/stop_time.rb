
class Fixnum
  def to_formatted_time
    rem = self / 60
    mins = rem % 60
    hours = rem / 60
    "%02d:%02d" % [ hours, mins ]
  end
end


class StopTime < ActiveRecord::Base
  belongs_to :trip
  belongs_to :line
  belongs_to :stop

  scope :coming, lambda { |line_id|
    now = Time.now 
    later = now + 2.hour
    where( :line_id => line_id ).
    where( "calendar & ? > 0", Calendar.from_time( now ) ).
    where( "arrival > ?", ( now.hour * 60 + now.min ) * 60 + now.sec ).
    where( "arrival < ?", ( later.hour * 60 + later.min ) * 60 + later.sec )
  }

end
