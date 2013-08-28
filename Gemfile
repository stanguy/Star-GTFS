source 'http://rubygems.org'

gem 'rails', '~>3.2.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'fastercsv', :platforms => :ruby_18
gem 'nokogiri'

gem 'pg'
gem 'activerecord-postgis-adapter'
gem 'inherited_resources'
gem 'apartment'

gem 'jquery-rails'

gem 'carrierwave'
gem 'mini_magick'
gem 'stringex'
gem 'sunspot_rails'
gem 'sitemap_generator'
gem 'em-http-request'

gem 'unicorn'

group :assets do
  gem 'sass-rails', "  ~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
  gem 'hogan_assets'
end

group :production do
  gem 'memcache-client'
end

group :development, :test do
#  gem 'silent-postgres'
  gem 'rspec-rails'
  gem 'webrat'
#  gem 'factory_girl_rails'
  gem 'rails-dev-boost', :git => 'git://github.com/thedarkone/rails-dev-boost.git', :require => 'rails_development_boost'
  gem 'rb-inotify', '~> 0.8.8'
  gem "better_errors"
  gem "binding_of_caller"
#  gem 'database_cleaner'
end

