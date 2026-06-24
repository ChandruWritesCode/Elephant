package models

import "time"

type Conversation struct {
	ChatUserID      string    `json:"chat_user_id"`
	Username        string    `json:"username"`
	DisplayName     string    `json:"display_name"`
	LastMessage     string    `json:"last_message"`
	LastMessageTime time.Time `json:"last_message_time"`
	SenderID        string    `json:"sender_id"`
	IsRead          bool      `json:"is_read"`
	UnreadCount     int       `json:"unread_count"`
}
