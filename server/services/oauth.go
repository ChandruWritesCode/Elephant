package services

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"

	"github.com/commandlinecoding/elephant/server/config"
)

type OAuthProfile struct {
	ID    string
	Email string
	Name  string
}

func GenerateStateToken() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return base64.URLEncoding.EncodeToString(b)
}

func ProcessCallback(ctx context.Context, provider, code string) (*OAuthProfile, error) {
	switch provider {
	case "google":
		return fetchGoogleUser(ctx, code)
	case "github":
		return fetchGithubUser(ctx, code)
	default:
		return nil, fmt.Errorf("unsupported provider context")
	}
}

func fetchGoogleUser(ctx context.Context, code string) (*OAuthProfile, error) {
	tok, err := config.GoogleConfig.Exchange(ctx, code)
	if err != nil {
		return nil, fmt.Errorf("google token exchange failed: %w", err)
	}

	client := config.GoogleConfig.Client(ctx, tok)
	resp, err := client.Get("https://www.googleapis.com/oauth2/v2/userinfo")
	if err != nil {
		return nil, fmt.Errorf("failed fetching google user data: %w", err)
	}
	defer resp.Body.Close()

	var data map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return &OAuthProfile{
		ID:    fmt.Sprintf("%v", data["id"]),
		Email: fmt.Sprintf("%v", data["email"]),
		Name:  fmt.Sprintf("%v", data["name"]),
	}, nil
}

func fetchGithubUser(ctx context.Context, code string) (*OAuthProfile, error) {
	tok, err := config.GithubConfig.Exchange(ctx, code)
	if err != nil {
		return nil, fmt.Errorf("github token exchange failed: %w", err)
	}

	client := config.GithubConfig.Client(ctx, tok)
	resp, err := client.Get("https://api.github.com/user")
	if err != nil {
		return nil, fmt.Errorf("failed fetching github user data: %w", err)
	}
	defer resp.Body.Close()

	var userRaw map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&userRaw); err != nil {
		return nil, err
	}

	profile := &OAuthProfile{
		ID:   fmt.Sprintf("%v", userRaw["id"]),
		Name: fmt.Sprintf("%v", userRaw["name"]),
	}

	if emailOpt, ok := userRaw["email"].(string); ok && emailOpt != "" {
		profile.Email = emailOpt
	} else {
		emailResp, err := client.Get("https://api.github.com/user/emails")
		if err == nil {
			defer emailResp.Body.Close()
			var emails []map[string]interface{}
			if err := json.NewDecoder(emailResp.Body).Decode(&emails); err == nil {
				for _, e := range emails {
					if primary, _ := e["primary"].(bool); primary {
						profile.Email = fmt.Sprintf("%v", e["email"])
						break
					}
				}
			}
		}
	}

	if profile.Email == "" {
		return nil, fmt.Errorf("unable to resolve verified primary email address context from github account")
	}

	return profile, nil
}
