package controllers

import (
	"encoding/json"
	"net/http"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/services"
)

func HandleHealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	data := services.PerformHealthCheck()
	
	resp := models.JSONResponse{
		Success: true,
		Data:    data,
	}

	if data["postgres"] == "down" {
		resp.Success = false
		resp.Error = "Database engine unreachable"
		w.WriteHeader(http.StatusInternalServerError)
	} else {
		w.WriteHeader(http.StatusOK)
	}
	
	_ = json.NewEncoder(w).Encode(resp)
}