#! /bin/bash

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  DROP EXTENSION postgis CASCADE;
  CREATE SCHEMA postgis;
  SET search_path = postgis;
  CREATE EXTENSION postgis;
EOSQL
