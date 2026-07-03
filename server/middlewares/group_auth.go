package middlewares

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
	"github.com/go-chi/chi/v5"
)

type groupContextKey string

const GroupRoleKey groupContextKey = "groupRole"

func GroupAuthGuard(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		uid, _ := r.Context().Value(UserIDKey).(string)
		groupID := chi.URLParam(r, "id")

		if groupID == "" {
			w.WriteHeader(http.StatusBadRequest)
			_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Missing channel identifier path parameter"})
			return
		}

		repo := repository.NewGroupRepository()
		role, err := repo.GetRole(r.Context(), groupID, uid)
		if err != nil {
			w.WriteHeader(http.StatusForbidden)
			_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Access denied: you are not a member of this group"})
			return
		}

		ctx := context.WithValue(r.Context(), GroupRoleKey, role)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func GroupAdminGuard(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		role, _ := r.Context().Value(GroupRoleKey).(string)
		if role != "admin" {
			w.WriteHeader(http.StatusForbidden)
			_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Administrative clearance privileges required"})
			return
		}
		next.ServeHTTP(w, r)
	})
}
