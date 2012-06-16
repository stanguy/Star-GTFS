# Load the rails application
require File.expand_path('../application', __FILE__)


# Initialize the rails application
StarGtfs::Application.initialize!

def in_memory_database?
#  puts
  ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::SQLite3Adapter" and
    StarGtfs::Application.config.database_configuration[Rails.env]['database'] == ':memory:'
end

if in_memory_database?
  puts "creating sqlite in memory database"
  load "#{RAILS_ROOT}/db/schema.rb" # use db agnostic schema by default
  # ActiveRecord::Migrator.up('db/migrate') # use migrations
end

if ENV.has_key? "GMAPS_KEY"
  StarGtfs::Application.config.gmaps_key = ENV["GMAPS_KEY"]
else
  StarGtfs::Application.config.gmaps_key = nil  
end
