package config

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/commandlinecoding/elephant/server/env"

	"github.com/jackc/pgx/v5/pgxpool"
)

// DB is exported globally
var DB *pgxpool.Pool

func InitDatabase() {
	// Build connection URI from your env constants
	uri := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		env.POSTGRES_USER,
		env.POSTGRES_PASSWORD,
		env.POSTGRES_HOST,
		env.POSTGRES_PORT,
		env.POSTGRES_DB,
	)

	// Create structural pool configuration settings
	poolConfig, err := pgxpool.ParseConfig(uri)
	if err != nil {
		log.Fatalf("Unable to parse database connection string: %v\n", err)
	}

	// Performance optimization configurations for high concurrency
	poolConfig.MaxConns = 25
	poolConfig.MinConns = 5
	poolConfig.MaxConnIdleTime = 30 * time.Minute

	// Instantiating the engine pool instance
	DB, err = pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		log.Fatalf("Unable to create database connection pool: %v\n", err)
	}

	// Ping health check
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err = DB.Ping(ctx); err != nil {
		log.Fatalf("Database runtime ping confirmation failed: %v\n", err)
	}

	fmt.Println("PostgreSQL connection pool running!")
}
