module Calendar
  MONDAY    = 1 << 0
  TUESDAY   = 1 << 1
  WEDNESDAY = 1 << 2
  THURSDAY  = 1 << 3
  FRIDAY    = 1 << 4
  SATURDAY  = 1 << 5
  SUNDAY    = 1 << 6

  def self.from_time t
    1 << ( ( t.wday - 1 ) % 7 )
  end
      
end
