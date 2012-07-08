Time::DATE_FORMATS[:french] = lambda { |time| 
  if time.hour == 0 and time.min == 0
    time.strftime("%d/%m/%Y")
  else
    time.strftime( "%d/%m/%Y (%H:%M)" )
  end
} 
