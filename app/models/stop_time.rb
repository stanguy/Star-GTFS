
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
  belongs_to :headsign # normalizawha?

  scope :coming, lambda { |line_id|
    now = Time.zone.now
    later = now + 2.hour
    value_now = ( now.hour * 60 + now.min ) * 60 + now.sec 
    value_later = ( later.hour * 60 + later.min ) * 60 + later.sec
    if now.day != later.day
      where( :line_id => line_id ).
        where( "( calendar & ? > 0 AND arrival > ? ) OR ( calendar & ? > 0 AND arrival < ? )", 
               Calendar.from_time( now ), value_now, 
               Calendar.from_time( later ), value_later )
    else
      where( :line_id => line_id ).
        where( "calendar & ? > 0", Calendar.from_time( now ) ).
        where( "arrival > ?", value_now ).
        where( "arrival < ?", ( later.hour * 60 + later.min ) * 60 + later.sec )
    end
  }

end
