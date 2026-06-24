package repository

import (
	"context"
	"os"
	"testing"

	"github.com/commandlinecoding/elephant/server/config"
)

func TestMain(m *testing.M) {	
	config.InitDatabase()
	code := m.Run()
	if config.DB != nil {
		config.DB.Close()
	}
	os.Exit(code)
}

func BenchmarkSearchUsers(b *testing.B) {
	repo := NewUserRepository()
	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := repo.SearchUsers(ctx, "testuser", 20, 0)
		if err != nil {
			b.Fatalf("Benchmark error: %v", err)
		}
	}
}