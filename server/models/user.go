package models

import "time"

type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	Email        string    `json:"email,omitempty"`
	DisplayName  string    `json:"display_name"`
	PasswordHash string    `json:"-"`
	GoogleID     string    `json:"google_id,omitempty"`
	GithubID     string    `json:"github_id,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}