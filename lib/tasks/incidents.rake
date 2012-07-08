
require 'opendata_api'

namespace :stargtfs do
  task :update_incidents => :environment do 
    InfoCollector.all.each do |ic|
      ic.perform
      ic.last_called_at = Time.now
      ic.save!
    end
  end
end
