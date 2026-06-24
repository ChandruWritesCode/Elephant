package middlewares

import (
	"context"
	"net/http"
	"strings"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/services"
	"encoding/json"
)

type contextKey string
const UserIDKey contextKey = "userId"

func AuthGuard(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			respondUnauthorized(w)
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			respondUnauthorized(w)
			return
		}

		uid, err := services.VerifyAccessToken(parts[1])
		if err != nil {
			respondUnauthorized(w)
			return
		}

		ctx := context.WithValue(r.Context(), UserIDKey, uid)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func respondUnauthorized(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: false,
		Error:   "Access token missing, expired or malformed",
	})
}