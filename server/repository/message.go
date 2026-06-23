package repository

import (
	"context"
	"time"

	"github.com/commandlinecoding/elephant/server/config"
	"github.com/commandlinecoding/elephant/server/models"
)

type MessageRepository struct{}

func NewMessageRepository() *MessageRepository {
	return &MessageRepository{}
}

func (r *MessageRepository) CreateMessage(ctx context.Context, senderID, receiverID, content string) (*models.Message, error) {
	query := `
		INSERT INTO messages (sender_id, receiver_id, content)
		VALUES ($1, $2, $3)
		RETURNING id, sender_id, receiver_id, content, created_at;
	`
	var msg models.Message
	err := config.DB.QueryRow(ctx, query, senderID, receiverID, content).Scan(
		&msg.ID,
		&msg.SenderID,
		&msg.ReceiverID,
		&msg.Content,
		&msg.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &msg, nil
}

func (r *MessageRepository) GetChatHistory(ctx context.Context, userA, userB string, before time.Time, limit int) ([]models.Message, error) {
	query := `
		SELECT id, sender_id, receiver_id, content, created_at
		FROM messages
		WHERE ((sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1))
		  AND created_at < $3
		ORDER BY created_at DESC
		LIMIT $4;
	`
	rows, err := config.DB.Query(ctx, query, userA, userB, before, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var history []models.Message = []models.Message{}
	for rows.Next() {
		var m models.Message
		err := rows.Scan(&m.ID, &m.SenderID, &m.ReceiverID, &m.Content, &m.CreatedAt)
		if err != nil {
			return nil, err
		}
		history = append(history, m)
	}
	return history, nil
}
