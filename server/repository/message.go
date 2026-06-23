package repository

import (
	"context"

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