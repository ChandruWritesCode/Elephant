package models

import "time"

type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	DisplayName  string    `json:"display_name"`
	PasswordHash string    `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
}