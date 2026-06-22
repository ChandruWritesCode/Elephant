package controllers

import (
	"encoding/json"
	"net/http"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/services"
)

type RegisterReq struct {
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Password    string `json:"password"`
}

func HandleRegister(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	var req RegisterReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false,
			Error:   "Invalid payload syntax",
		})
		return
	}

	svc := services.NewUserService()
	user, err := svc.Register(r.Context(), req.Username, req.DisplayName, req.Password)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	tokens, err := services.GenerateTokenPair(user.ID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false,
			Error:   "Token generation failure",
		})
		return
	}

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: true,
		Data: map[string]interface{}{
			"user":   user,
			"tokens": tokens,
		},
	})
}