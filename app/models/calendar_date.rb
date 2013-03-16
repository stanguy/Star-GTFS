class CalendarDate < ActiveRecord::Base
  attr_accessible :calendar_id, :exception_date, :exclusion

  belongs_to :calendar

end
