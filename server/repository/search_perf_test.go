package repository

import (
	"context"
	"testing"
	"time"
)

func TestSearchLatencyAtScale(t *testing.T) {
	repo := NewUserRepository()
	ctx := context.Background()

	start := time.Now()
	results, err := repo.SearchUsers(ctx, "mockuser55", 20, 0)
	duration := time.Since(start)

	if err != nil {
		t.Fatalf("Search query execution failed: %v", err)
	}

	t.Logf("Found %d records. Latency: %v", len(results), duration)

	if duration > 200*time.Millisecond {
		t.Errorf("Latency target breached: search took %v, ceiling is 200ms", duration)
	}
}
