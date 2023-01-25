#! /bin/sh

rake db:migrate

# in case of wrongful termination, somehow
rm -f /app/tmp/pids/server.pid

exec rails s -b 0.0.0.0
