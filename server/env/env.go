package env

import (
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
)

// global variables
var (
	HOST string
	PORT string

	POSTGRES_USER     string
	POSTGRES_PASSWORD string
	POSTGRES_DB       string
	POSTGRES_PORT     string
	POSTGRES_HOST     string

	JWT_SECRET string

	ARGON_MEMORY      string
	ARGON_ITERATIONS  string
	ARGON_PARALLELISM string
)

func init() {
	cwd, err := os.Getwd()
	if err == nil {
		for {
			target := filepath.Join(cwd, ".env")
			if _, err := os.Stat(target); err == nil {
				_ = godotenv.Load(target)
				break
			}
			parent := filepath.Dir(cwd)
			if parent == cwd {
				break
			}
			cwd = parent
		}
	}

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

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
