
require 'csv'

namespace :stargtfs do
  task :maptimize_export => :environment do
    str = CSV.generate do |csv|
      csv << [ "id", "lat", "lng" ]
      Agency.where( slug: [ "rennes", "saint-lo" ] ).each do |agency|
        Apartment::Database.switch agency.db_slug
        Stop.all.each do |stop|
          csv << [ stop.slug, stop.lat, stop.lon ]
        end
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
