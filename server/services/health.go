package services

import (
	"context"
	"time"

	"github.com/commandlinecoding/elephant/server/config"
)

func PerformHealthCheck() map[string]interface{} {
	status := "up"
	if err := config.DB.Ping(context.Background()); err != nil {
		status = "down"
	}

	return map[string]interface{} {
		"postgres": status,
		"timestamp": time.Now().UTC(),
	}
}