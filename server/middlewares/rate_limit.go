package middlewares

import (
	"encoding/json"
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/commandlinecoding/elephant/server/models"
)

type clientBucket struct {
	tokens     float64
	lastRefill time.Time
}

type RateLimiter struct {
	mu      sync.Mutex
	clients map[string]*clientBucket
	rate    float64 // tokens per second
	max     float64 // max burst capacity
}

func NewRateLimiter(rate, max float64) *RateLimiter {
	return &RateLimiter{
		clients: make(map[string]*clientBucket),
		rate:    rate,
		max:     max,
	}
}

func (rl *RateLimiter) Limit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			ip = r.RemoteAddr // Fallback in case string structure varies
		}

		rl.mu.Lock()
		client, exists := rl.clients[ip]
		now := time.Now()

		if !exists {
			client = &clientBucket{
				tokens:     rl.max,
				lastRefill: now,
			}
			rl.clients[ip] = client
		} else {
			elapsed := now.Sub(client.lastRefill).Seconds()
			client.tokens += elapsed * rl.rate
			if client.tokens > rl.max {
				client.tokens = rl.max
			}
			client.lastRefill = now
		}

		if client.tokens < 1.0 {
			rl.mu.Unlock()
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusTooManyRequests)
			_ = json.NewEncoder(w).Encode(models.JSONResponse{
				Success: false,
				Error:   "Rate limit exceeded. Too many search requests.",
			})
			return
		}

		client.tokens -= 1.0
		rl.mu.Unlock()

		next.ServeHTTP(w, r)
	})
}
