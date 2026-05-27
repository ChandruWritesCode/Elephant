package env

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// global variables
var (
	// Server configurations
	HOST string
	PORT string

	// PostgreSQL database coordinates
	POSTGRES_USER     string
	POSTGRES_PASSWORD string
	POSTGRES_DB       string
	POSTGRES_PORT     string
	POSTGRES_HOST     string

	// Security & Token configurations
	JWT_SECRET string

	// Cryptography parameters (Argon2id tuning)
	ARGON_MEMORY      string
	ARGON_ITERATIONS  string
	ARGON_PARALLELISM string
)

func init() {
	// load the file into the environment
	if _, err := os.Stat("../.env"); err == nil {
		if err := godotenv.Load("../.env"); err != nil {
			log.Printf("Warning: Found .env but failed to parse it: %v", err)
		}
	} else if _, err := os.Stat(".env"); err == nil {
		_ = godotenv.Load(".env")
	}

	// assign the values with fallbacks
	HOST = getEnv("HOST", "127.0.0.1")
	PORT = getEnv("PORT", "3000")

	POSTGRES_USER = getEnv("POSTGRES_USER", "postgres")
	POSTGRES_PASSWORD = getEnv("POSTGRES_PASSWORD", "very_strong_password")
	POSTGRES_DB = getEnv("POSTGRES_DB", "myapi_db")
	POSTGRES_PORT = getEnv("POSTGRES_PORT", "5432")
	POSTGRES_HOST = getEnv("POSTGRES_HOST", "localhost")

	JWT_SECRET = getEnv("JWT_SECRET", "default-long-safe-secret-key-string")

	ARGON_MEMORY = getEnv("ARGON_MEMORY", "65536")
	ARGON_ITERATIONS = getEnv("ARGON_ITERATIONS", "3")
	ARGON_PARALLELISM = getEnv("ARGON_PARALLELISM", "2")
}

// Smart fallback defaults if an env variable is missing locally
func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
