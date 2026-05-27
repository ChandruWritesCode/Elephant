package controllers

import (
	"encoding/json"
	"net/http"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/services"
)



func HandleHealthCheck(w http.ResponseWriter, r *http.Request) {
	report := services.PerformHealthCheck()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(models.APIResponse{Success: true, Message: "Operational", Data: report})
}