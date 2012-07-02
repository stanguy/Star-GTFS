
require 'csv'

namespace :stargtfs do
  task :maptimize_export => :environment do
    str = CSV.generate do |csv|
      csv << [ "id", "lat", "lng" ]
      Stop.all.each do |stop|
        csv << [ stop.slug, stop.lat, stop.lon ]
      end
    end
    upload_url = 'http://v2.maptimize.com/api/v2/%s/import' % Rails.configuration.api_keys[:MAPTIMIZE]
    resource = RestClient::Resource.new upload_url, ENV['STARGTFS_MAPTIMIZE_TOKEN'], 'X'
    r = resource.put str, :content_type => 'text/csv'
    p r
  end

end
