package controllers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
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

	// Generate the tokens
	tokens, err := services.GenerateTokenPair(user.ID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false,
			Error:   "Token generation failure",
		})
		return
	}

	// FIX: Persist the registration refresh token to the database
	tokenRepo := repository.NewRefreshTokenRepository()
	hashedRt := services.HashToken(tokens.RefreshToken)
	expiry := time.Now().Add(7 * 24 * time.Hour)

	if err := tokenRepo.StoreToken(r.Context(), user.ID, hashedRt, expiry); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false,
			Error:   "Failed to securely record registration token metrics",
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


type LoginReq struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func HandleLogin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req LoginReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Invalid json payload structure"})
		return
	}

	svc := services.NewAuthService()
	user, tokens, err := svc.Login(r.Context(), req.Username, req.Password)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: true,
		Data: map[string]interface{}{
			"user":   user,
			"tokens": tokens,
		},
	})
}

type RefreshReq struct {
	RefreshToken string `json:"refresh_token"`
}

func HandleRefresh(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req RefreshReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false, 
			Error: "Invalid json payload structure",
		})
		return
	}

	if req.RefreshToken == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false, 
			Error: "Refresh token parameter missing",
		})
		return
	}

	svc := services.NewAuthService()
	tokens, err := svc.Refresh(r.Context(), req.RefreshToken)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{
			Success: false, 
			Error: err.Error(),
		})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: true,
		Data:    tokens,
	})
}