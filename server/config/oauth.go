package config

import (
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/github"
	"golang.org/x/oauth2/google"

	"github.com/commandlinecoding/elephant/server/env"
)

var GoogleConfig *oauth2.Config
var GithubConfig *oauth2.Config

func InitOAuth() {
	GoogleConfig = &oauth2.Config{
		ClientID:     env.GOOGLE_CLIENT_ID,
		ClientSecret: env.GOOGLE_CLIENT_SECRET,
		RedirectURL:  env.GOOGLE_REDIRECT_URL,
		Scopes: []string{
			"https://www.googleapis.com/auth/userinfo.profile",
			"https://www.googleapis.com/auth/userinfo.email",
		},
		Endpoint: google.Endpoint,
	}

	GithubConfig = &oauth2.Config{
		ClientID:     env.GITHUB_CLIENT_ID,
		ClientSecret: env.GITHUB_CLIENT_SECRET,
		RedirectURL:  env.GITHUB_REDIRECT_URL,
		Scopes:       []string{"user:email", "read:user"},
		Endpoint:     github.Endpoint,
	}
}
