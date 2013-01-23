
require 'csv'

namespace :stargtfs do
  task :maptimize_export => :environment do
    str = CSV.generate do |csv|
      csv << [ "id", "lat", "lng" ]
      Stop.all.each do |stop|
        csv << [ stop.slug, stop.lat, stop.lon ]
      end
    end
    r = Net::HTTP.start( 'v2.maptimize.com', 80 ) do |http|
      req = Net::HTTP::Put.new('/api/v2/%s/import' % Rails.configuration.api_keys[:MAPTIMIZE] )
      req.body = str
      req.content_type = 'text/csv'
      req.basic_auth ENV['STARGTFS_MAPTIMIZE_TOKEN'], 'X'
      http.request(req)
    end
    p r.body
  end

end
