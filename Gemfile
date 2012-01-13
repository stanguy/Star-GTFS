source 'http://rubygems.org'

gem 'rails', '~>3.1.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'fastercsv', :platforms => :ruby_18
gem 'yajl-ruby'
gem 'nokogiri'

gem 'pg'
gem 'spatial_adapter', :git => "https://github.com/Empact/spatial_adapter.git"
gem 'inherited_resources'

gem 'jquery-rails'

gem 'stringex'

group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
  gem 'hogan_assets'
end

group :production do
  gem 'memcache-client'
end

group :development, :test do
  gem 'silent-postgres'
  gem 'rspec-rails'
  gem 'webrat'
  gem 'factory_girl_rails'
  gem 'rails-dev-boost', :git => 'git://github.com/thedarkone/rails-dev-boost.git', :require => 'rails_development_boost'
  gem 'unicorn'
end

