package config

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/commandlinecoding/elephant/server/env"
	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func isLocalHost(host string) bool {
	h := strings.ToLower(host)
	return h == "localhost" || h == "127.0.0.1" || h == "::1" || strings.HasPrefix(h, "172.")
}

func InitDatabase() {
	sslMode := "require"
	if isLocalHost(env.POSTGRES_HOST) {
		sslMode = "disable"
	}

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
		env.POSTGRES_USER,
		env.POSTGRES_PASSWORD,
		env.POSTGRES_HOST,
		env.POSTGRES_PORT,
		env.POSTGRES_DB,
		sslMode,
	)

	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		log.Fatalf("Unable to parse database DSN config string: %v", err)
	}

	cfg.MaxConns = 25                      // Prevent socket exhaustion on standard containers
	cfg.MinConns = 5                       // Keep cold start latency low
	cfg.MaxConnLifetime = 30 * time.Minute // Cycle old sockets out safely
	cfg.MaxConnIdleTime = 15 * time.Minute // Prune idle workers under low load

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	DB, err = pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("Failed to initialize production pgxpool framework: %v", err)
	}

	if err := DB.Ping(ctx); err != nil {
		log.Fatalf("Database validation ping failed: %v", err)
	}

	log.Println("PostgreSQL connection pool running with production configurations!")
}
