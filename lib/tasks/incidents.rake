
require 'opendata_api'

namespace :stargtfs do
  task :update_incidents => :environment do 
    Agency.all.each do |agency|
      Apartment::Database.switch agency.db_slug
      InfoCollector.all.each do |ic|
        ic.perform
        ic.last_called_at = Time.now
        ic.save!
      end
    end
  end
end
