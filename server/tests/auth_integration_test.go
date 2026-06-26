package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"
)

func Test_Auth(t *testing.T) {
	host, port := os.Getenv("HOST"), os.Getenv("PORT")
	fmt.Printf("%s %s", host, port)
	if host == "" {
		host = "localhost"
	}
	if port == "" {
		port = "8080"
	}

	baseURL := fmt.Sprintf("http://%s:%s", host, port)

	uniqueUsername := fmt.Sprintf("user%d", time.Now().Unix())
	password := "SecurePassword123!"

	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	var fullUsername string
	t.Run("Register New User", func(t *testing.T) {
		regPayLoad := map[string]string{
			"username":     uniqueUsername,
			"display_name": "Tester ABC",
			"password":     password,
		}

		body, err := json.Marshal(regPayLoad)
		if err != nil {
			t.Fatalf("Marshal failed: %v", err)
		}

		resp, err := client.Post(baseURL+"/api/auth/register", "application/json", bytes.NewBuffer(body))
		if err != nil {
			t.Fatalf("Failed to hit register endpoint at %s: %v", baseURL, err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusCreated {
			t.Fatalf("Expected 201 on registration, got %d", resp.StatusCode)
		}

		var regResp struct {
			Data struct {
				User struct {
					Username string `json:"username"`
				} `json:"user"`
			} `json:"data"`
		}
		
		if err:= json.NewDecoder(resp.Body).Decode(&regResp);
		err != nil {
			t.Fatalf("Failed to decode register: %v", err)
		}

		if regResp.Data.User.Username == "" {
			t.Fatalf("response did not return a username")
		}

		fullUsername = regResp.Data.User.Username
		fmt.Printf("fullUsername= %s  password= %s\n",fullUsername,password)

	})

	time.Sleep(1*time.Second)

	var accessToken string
	var refreshToken string

	t.Run("Login User", func(t *testing.T) {

		loginPayLoad := map[string]string{
			"username": fullUsername,
			"password": password,
		}

		body, err := json.Marshal(loginPayLoad)
		if err != nil {
			t.Fatalf("Marshal Failed: %v", err)
		}

		resp, err := client.Post(baseURL+"/api/auth/login", "application/json", bytes.NewBuffer(body))
		if err != nil {
			t.Fatalf("Failed to hit login endpoint: %v", err)
		}

		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("Expected 200 OK on login, got: %d %s %s", resp.StatusCode,fullUsername,password)
		}

		var loginResp struct {
			Success bool `json:"success"`
			Data    struct {
				Tokens struct {
					AccessToken  string `json:"access_token"`
					RefreshToken string `json:"refresh_token"`
				} `json:"tokens"`
			} `json:"data"`
		}

		err = json.NewDecoder(resp.Body).Decode(&loginResp)
		if err != nil {
			t.Fatalf("Failed to parse login token, Response: %v", err)
		}

		accessToken = loginResp.Data.Tokens.AccessToken
		refreshToken = loginResp.Data.Tokens.RefreshToken

		if accessToken == "" {
			t.Fatalf("empty access token returned")
		}

		if refreshToken == "" {
			t.Fatalf("empty refresh token returned")
		}
	})

	t.Run("Refresh Token", func(t *testing.T) {
		if refreshToken == "" {
			t.Skip("Skippping token refresh as login failed to capture token")
		}

		refPayLoad := map[string]string{
			"refresh_token": refreshToken,
		}

		body, _ := json.Marshal(refPayLoad)

		resp, err := client.Post(baseURL+"/api/auth/refresh", "application/json", bytes.NewBuffer(body))
		if err != nil {
			t.Fatalf("Failed to hit refresh endpoint: %v", err)
		}

		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("Expected 200 OK on token refresh, got: %d", resp.StatusCode)
		}
	})
}
