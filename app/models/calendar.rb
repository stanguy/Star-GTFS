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

  def self.from_time t
    1 << ( ( t.wday - 1 ) % 7 )
  end

  def self.range_to_str c
    days = (0..6).collect {|ds| d = ( 1 << ds ); ( c & d > 0 ) ? CAL_STRINGS[d] : nil }.delete_if &:nil?
    days.join ","
  end
      
      
end
