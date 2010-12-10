
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
end
