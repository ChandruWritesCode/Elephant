package tests

import (
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"
)

func Test_AuthMiddleware(t *testing.T) {
	host, port := os.Getenv("HOST"), os.Getenv("PORT")

	if host == "" {
		host = "localhost"
	}

	if port == "" {
		port = "8080"
	}

	baseURL := fmt.Sprintf("http://%s:%s", host, port)

	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	t.Run("Missing Token", func(t *testing.T) {
		req, _ := http.NewRequest("GET", baseURL+"/api/users/me", nil)

		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("Failed to reach middleware endpoint: %v", err)
		}

		if resp.StatusCode != http.StatusUnauthorized {
			t.Fatalf("Expected 401 Unauthorized for missing token, got: %d", resp.StatusCode)
		}
	})

	t.Run("Expired or Bad Token", func(t *testing.T) {
		req, _ := http.NewRequest("GET", baseURL+"/api/users/me", nil)

		req.Header.Set("Authorization", "Bearer an.expired.or.bad.token,string")

		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("Failed to reach middleware endpoint: %v", err)
		}

		if resp.StatusCode != http.StatusUnauthorized {
			t.Fatalf("Expected 401 Unauthorized for Expired or Bad token, got: %d", resp.StatusCode)
		}
	})

}
