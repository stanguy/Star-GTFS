class Calendar < ActiveRecord::Base
#  attr_accessible :days, :end_date, :src_id, :start_date
  
  has_many :calendar_dates, :dependent => :delete_all
  has_many :trips

  MONDAY    = 1 << 0
  TUESDAY   = 1 << 1
  WEDNESDAY = 1 << 2
  THURSDAY  = 1 << 3
  FRIDAY    = 1 << 4
  SATURDAY  = 1 << 5
  SUNDAY    = 1 << 6

  WEEKDAY   = MONDAY | TUESDAY | WEDNESDAY | THURSDAY | FRIDAY 

  CAL_STRINGS = { MONDAY => 'Lu', TUESDAY => 'Ma', WEDNESDAY => 'Me', THURSDAY => 'Je', FRIDAY => 'Ve', SATURDAY => 'Sa', SUNDAY => 'Di' }

  def range_to_str
    case self.days
    when WEEKDAY
      [ CAL_STRINGS[MONDAY], CAL_STRINGS[FRIDAY] ].join('-')
    else
      days = (0..6).collect {|ds| d = ( 1 << ds ); ( self.days & d > 0 ) ? CAL_STRINGS[d] : nil }.delete_if &:nil?
      days.join ","
    end
  end


  def self.days_from_time t
    1 << ( ( t.wday - 1 ) % 7 )
  end

  scope :from_time, lambda { |t|
    date = t.to_date
    dates = CalendarDate.where( exception_date: date )
    except_include = dates.select {|d| ! d.exclusion }.collect(&:calendar_id)
    if except_include.empty?
      include_test = "?"
      except_include = false
    else
      include_test = "id IN (?)"
    end
    except_exclude = dates.select {|d|   d.exclusion }.collect(&:calendar_id)
    if except_exclude.empty?
      exclude_test = "?"
      except_exclude = true
    else
      exclude_test = "id NOT IN (?)"
    end
    where( "( end_date >= ? AND start_date <= ? AND days & ? > 0 AND #{exclude_test} ) OR #{include_test}", date, date, 1 << ( ( t.wday - 1 ) % 7 ), except_exclude, except_include )
  }
  def to_s
    [ self.range_to_s,
      self.days ].join("-")
  end
      
  def range_to_s
    [ self.start_date.strftime( "%Y%m%d" ), 
      self.end_date.strftime( "%Y%m%d" ) ].join( "-")
  end
end
