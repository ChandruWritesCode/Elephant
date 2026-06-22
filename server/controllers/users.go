package controllers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/services"
)

func HandleUsers(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"status": "users stub active"}`))
}

func HandleUserSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract parameters
	q := r.URL.Query().Get("q")
	pageStr := r.URL.Query().Get("page")
	limitStr := r.URL.Query().Get("limit")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)

	svc := services.NewUserService()
	users, err := svc.Search(r.Context(), q, page, limit)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false,
			Error:   "Failed to execute user directory search operations",
		})
		return
	}

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: true,
		Data:    users,
	})
}
