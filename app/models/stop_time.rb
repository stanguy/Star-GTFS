
class Fixnum
  def to_formatted_time
    "%02d:%02d" % self.to_hm
  end
  def to_hm fix_24 = true
    rem = self / 60
    mins = rem % 60
    hours = rem / 60
    if hours >= 24 && fix_24
      hours -= 24
    end
    [ hours, mins ]
  end     
end


class StopTime < ActiveRecord::Base
  belongs_to :trip
  belongs_to :line
  belongs_to :stop
  belongs_to :headsign # normalizawha?
  belongs_to :calendar

  scope :coming, lambda { |line_id,p_now|
    unless p_now.nil?
      now = p_now
    else
      now = Time.zone.now
    end
    later = now + 2.hour
    value_now = ( now.hour * 60 + now.min ) * 60 + now.sec 
    value_later = ( later.hour * 60 + later.min ) * 60 + later.sec
    if now.day != later.day
      where( :line_id => line_id ).
        where( "( calendar_id IN (?) AND arrival > ? ) OR ( calendar_id IN (?) AND arrival < ? )",
               Calendar.from_time( now ), value_now,
               Calendar.from_time( later ), value_later )
    elsif now.hour < 8
      where( :line_id => line_id ).
        where( "( calendar_id IN (?) AND arrival > ? ) OR ( calendar_id IN (?) AND arrival > ? AND arrival < ? )",
               Calendar.from_time( now - 1.day ), value_now + 24.hours,
               Calendar.from_time( now ), value_now, value_later )
    else
      where( :line_id => line_id ).
        where( calendar_id: Calendar.from_time( now ) ).
        where( :arrival => value_now..value_later )
    end
  }

end
