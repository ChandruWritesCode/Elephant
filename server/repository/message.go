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
		SELECT id, sender_id, receiver_id, content, created_at, is_read
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
		err := rows.Scan(&m.ID, &m.SenderID, &m.ReceiverID, &m.Content, &m.CreatedAt, &m.IsRead)
		if err != nil {
			return nil, err
		}
		history = append(history, m)
	}
	return history, nil
}

func (r *MessageRepository) GetConversations(ctx context.Context, userID string) ([]models.Conversation, error) {
	query := `
		WITH last_messages AS (
			SELECT DISTINCT ON (chat_user_id)
				CASE WHEN sender_id = $1 THEN receiver_id ELSE sender_id END AS chat_user_id,
				content,
				sender_id,
				created_at,
				is_read
			FROM messages
			WHERE sender_id = $1 OR receiver_id = $1
			ORDER BY chat_user_id, created_at DESC
		),
		unread_counts AS (
			SELECT sender_id, COUNT(*) AS count
			FROM messages
			WHERE receiver_id = $1 AND is_read = FALSE
			GROUP BY sender_id
		)
		SELECT 
			lm.chat_user_id,
			u.username,
			u.display_name,
			lm.content,
			lm.created_at,
			lm.sender_id,
			lm.is_read,
			COALESCE(uc.count, 0)::INT AS unread_count
		FROM last_messages lm
		JOIN users u ON u.id = lm.chat_user_id
		LEFT JOIN unread_counts uc ON uc.sender_id = lm.chat_user_id
		ORDER BY lm.created_at DESC;
	`

	rows, err := config.DB.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.Conversation = []models.Conversation{}
	for rows.Next() {
		var c models.Conversation
		err := rows.Scan(
			&c.ChatUserID,
			&c.Username,
			&c.DisplayName,
			&c.LastMessage,
			&c.LastMessageTime,
			&c.SenderID,
			&c.IsRead,
			&c.UnreadCount,
		)
		if err != nil {
			return nil, err
		}
		list = append(list, c)
	}
	return list, nil
}

func (r *MessageRepository) MarkAsRead(ctx context.Context, receiverID, senderID string) error {
	query := `
		UPDATE messages
		SET is_read = TRUE
		WHERE receiver_id = $1 AND sender_id = $2 AND is_read = FALSE;
	`
	_, err := config.DB.Exec(ctx, query, receiverID, senderID)
	return err
}