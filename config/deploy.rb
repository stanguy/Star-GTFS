require "bundler/capistrano"
require 'capistrano/shared_file'

set :application, "Star-GTFS"
set :repository,  "https://github.com/stanguy/Star-GTFS.git"

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "maps-app"                          # Your HTTP server, Apache/etc
role :app, "maps-app"                          # This may be the same as your `Web` server
role :db,  "maps-app", :primary => true # This is where Rails migrations will run

set :user, 'stargtfs'
set :deploy_to, '/home/stargtfs/app'

set :use_sudo, false
set :shared_children, shared_children + %w{public/uploads}
set :shared_files, %w(config/database.yml config/initializers/secret_token.rb config/sunspot.yml)

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{File.join(current_path,'tmp','pids','unicorn.pid')}`"
  end
end
