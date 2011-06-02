module Calendar
  MONDAY    = 1 << 0
  TUESDAY   = 1 << 1
  WEDNESDAY = 1 << 2
  THURSDAY  = 1 << 3
  FRIDAY    = 1 << 4
  SATURDAY  = 1 << 5
  SUNDAY    = 1 << 6

  WEEKDAY   = MONDAY | TUESDAY | WEDNESDAY | THURSDAY | FRIDAY 

  CAL_STRINGS = { MONDAY => 'Lu', TUESDAY => 'Ma', WEDNESDAY => 'Me', THURSDAY => 'Je', FRIDAY => 'Ve', SATURDAY => 'Sa', SUNDAY => 'Di' }

  HOLIDAYS = [  20101225,
                20110101,
                20110425,
                20110501,
                20110508,
                20110602,
                20110613,
                20110714,
                20110815,
                20111101,
                20111111,
                20111225,
                20120101,
                20120409,
                20120501,
                20120508,
                20120517,
                20120528,
                20120714,
                20120815,
                20121101,
                20121111,
                20121225,
                20130101,
                20130401,
                20130501,
                20130508,
                20130509,
                20130519,
                20130714,
                20130815,
                20131101,
                20131111,
                20131225 ]
  
  def self.from_time t
    if HOLIDAYS.include?( t.year * 10000 + t.month * 100 + t.day )
      return SUNDAY
    end
    1 << ( ( t.wday - 1 ) % 7 )
  end

  def self.range_to_str c
    case c
    when WEEKDAY
      [ CAL_STRINGS[MONDAY], CAL_STRINGS[FRIDAY] ].join('-')
    else
      days = (0..6).collect {|ds| d = ( 1 << ds ); ( c & d > 0 ) ? CAL_STRINGS[d] : nil }.delete_if &:nil?
      days.join ","
    end
  end
      
      
end
