#!/bin/sh
set -e

echo "Intializing Elephant Server"

DB_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo "Waiting for database..."
until pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}"; do
  sleep 1
done

echo "Running migrations..."
psql "${DB_URL}" << 'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);
SQL

for migration in /app/migrations/*_up.sql; do
    filename=$(basename "$migration")
    already_applied=$(psql "${DB_URL}" -tAc \
        "SELECT COUNT(*) FROM schema_migrations WHERE filename = '${filename}'")
    if [ "$already_applied" = "0" ]; then
        echo "Applying ${filename}..."
        psql "${DB_URL}" -f "$migration"
        psql "${DB_URL}" -c \
            "INSERT INTO schema_migrations (filename) VALUES ('${filename}')"
        echo "${filename} applied."
    else
        echo "${filename} already applied, skipping."
    fi
done

echo "Migrations complete. Starting server..."
exec ./elephant-server