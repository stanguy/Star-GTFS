RAILS_ROOT = ENV['RAILS_ROOT'] || File.expand_path(File.dirname(File.dirname(__FILE__)))
rails_env = ENV['RAILS_ENV'] || 'production'
worker_processes (rails_env == 'production' ? 8 : 4)
preload_app true
timeout 30

before_fork do |server, worker|
  old_pid = RAILS_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end
