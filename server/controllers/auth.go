package controllers

import (
	"encoding/json"
	"net/http"

	"github.com/commandlinecoding/elephant/server/models"
)

func HandleAuth(w http.ResponseWriter, r *http.Request) {	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(models.APIResponse{Success: true, Message: "Operational", Data: "full auth setup coming soon..."})	
}