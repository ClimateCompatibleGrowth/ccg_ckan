#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE "$DATASTORE_READONLY_USER" NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD '$DATASTORE_READONLY_PASSWORD';
    CREATE DATABASE "$DATASTORE_DB" OWNER "$CKAN_DB_USER" ENCODING 'utf-8';
EOSQL