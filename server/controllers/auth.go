package controllers

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/commandlinecoding/elephant/server/config"
	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
	"github.com/commandlinecoding/elephant/server/services"
	"github.com/go-chi/chi/v5"
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
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Invalid payload syntax"})
		return
	}

	svc := services.NewUserService()
	user, err := svc.Register(r.Context(), req.Username, req.DisplayName, req.Password)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	tokens, err := services.GenerateTokenPair(user.ID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Token generation failure"})
		return
	}

	tokenRepo := repository.NewRefreshTokenRepository()
	hashedRt := services.HashToken(tokens.RefreshToken)
	expiry := time.Now().Add(7 * 24 * time.Hour)

	if err := tokenRepo.StoreToken(r.Context(), user.ID, hashedRt, expiry); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Failed to securely record registration token metrics"})
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
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Invalid json payload structure"})
		return
	}

	if req.RefreshToken == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Refresh token parameter missing"})
		return
	}

	svc := services.NewAuthService()
	tokens, err := svc.Refresh(r.Context(), req.RefreshToken)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: true, Data: tokens})
}

func HandleOAuthRedirect(w http.ResponseWriter, r *http.Request) {
	provider := chi.URLParam(r, "provider")
	state := services.GenerateStateToken()

	cookie := &http.Cookie{
		Name:     "oauth_state",
		Value:    state,
		Path:     "/",
		HttpOnly: true,
		Secure:   false,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   300,
	}
	http.SetCookie(w, cookie)

	var url string
	switch provider {
	case "google":
		url = config.GoogleConfig.AuthCodeURL(state)
	case "github":
		url = config.GithubConfig.AuthCodeURL(state)
	default:
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Unsupported OAuth provider context"})
		return
	}

	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

func HandleOAuthCallback(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	provider := chi.URLParam(r, "provider")
	code := r.URL.Query().Get("code")
	state := r.URL.Query().Get("state")

	cookie, err := r.Cookie("oauth_state")
	if err != nil || cookie.Value != state {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "State token match validation failed"})
		return
	}

	profile, err := services.ProcessCallback(r.Context(), provider, code)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	userRepo := repository.NewUserRepository()
	u, err := userRepo.FindByProviderID(r.Context(), provider, profile.ID)
	if err != nil {
		u, err = userRepo.FindByEmail(r.Context(), profile.Email)
		if err == nil {
			_ = userRepo.LinkProviderAccount(r.Context(), u.ID, provider, profile.ID)
		} else {
			emailHandle := strings.Split(profile.Email, "@")[0]
			baseUsername := cleanAlphanumeric(emailHandle)

			var username string
			for {
				randomDigits := generateRandom4Digits()
				username = fmt.Sprintf("%s.%s", baseUsername, randomDigits)

				exists, err := userRepo.UsernameExists(r.Context(), username)
				if err == nil && !exists {
					break
				}
			}

			u, err = userRepo.CreateOAuthUser(r.Context(), username, profile.Email, profile.Name, provider, profile.ID)
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Failed to allocate user credentials"})
				return
			}
		}
	}

	tokens, err := services.GenerateTokenPair(u.ID)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	tokenRepo := repository.NewRefreshTokenRepository()
	hashedRt := services.HashToken(tokens.RefreshToken)
	expiry := time.Now().Add(7 * 24 * time.Hour)
	_ = tokenRepo.StoreToken(r.Context(), u.ID, hashedRt, expiry)

	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: true,
		Data: map[string]interface{}{
			"user":   u,
			"tokens": tokens,
		},
	})
}

func cleanAlphanumeric(s string) string {
	reg := regexp.MustCompile("[^a-zA-Z0-9]")
	processed := reg.ReplaceAllString(s, "")
	if processed == "" {
		return "user"
	}
	return processed
}

func generateRandom4Digits() string {
	n, err := rand.Int(rand.Reader, big.NewInt(10000))
	if err != nil {
		return "1729"
	}
	return fmt.Sprintf("%04d", n.Int64())
}
