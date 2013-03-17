class CalendarDate < ActiveRecord::Base
  attr_accessible :calendar_id, :exception_date, :exclusion

  belongs_to :calendar
  
  def to_s
    [ self.exception_date.strftime( "%Y%m%d"), self.exclusion.to_s ].join("-")
  end
      
  
end
