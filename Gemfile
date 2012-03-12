source 'http://rubygems.org'

gem 'rails', '~>3.2.0'

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
gem 'sunspot_rails'
gem 'sitemap_generator'

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
  gem 'unicorn'
end

