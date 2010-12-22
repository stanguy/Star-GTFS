

require 'csv'

str = CSV.generate do |csv|
  csv << [ "id", "lat", "lng" ]
  Stop.all.each do |stop|
    csv << [ stop.id, stop.lat, stop.lon ]
  end
end
puts str
