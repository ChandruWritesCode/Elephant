#!/bin/sh
set -e

DB_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo "Verifying migration registry..."
psql "${DB_URL}" << 'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);
SQL

migration_exists=0
for f in /migrations/*_up.sql; do
    [ -e "$f" ] && migration_exists=1 && break
done

if [ "$migration_exists" = 1 ]; then
    for migration in /migrations/*_up.sql; do
        filename=$(basename "$migration")
        already_applied=$(psql "${DB_URL}" -tAc \
            "SELECT COUNT(*) FROM schema_migrations WHERE filename = '${filename}'")
        
        if [ "$already_applied" = "0" ]; then
            echo "Applying: ${filename}"
            psql "${DB_URL}" -f "$migration"
            psql "${DB_URL}" -c "INSERT INTO schema_migrations (filename) VALUES ('${filename}')"
        else
            echo "Skipping (Already Applied): ${filename}"
        fi
    done
else
    echo "No migration files found matching *_up.sql"
fi

echo "Database migrations updated successfully."