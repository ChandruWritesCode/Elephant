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
		WITH raw_conversations AS (
			-- Enclosing Part A inside explicit parentheses to isolate its internal ORDER BY
			(SELECT DISTINCT ON (CASE WHEN sender_id = $1::uuid THEN receiver_id ELSE sender_id END)
				CASE WHEN sender_id = $1::uuid THEN receiver_id ELSE sender_id END AS chat_user_id,
				'direct' AS type,
				content,
				sender_id,
				created_at,
				is_read,
				NULL::UUID AS group_id
			FROM messages
			WHERE (sender_id = $1::uuid OR receiver_id = $1::uuid) AND group_id IS NULL
			ORDER BY CASE WHEN sender_id = $1::uuid THEN receiver_id ELSE sender_id END, created_at DESC)

			UNION ALL

			-- Enclosing Part B inside explicit parentheses to isolate its internal ORDER BY
			(SELECT DISTINCT ON (m.group_id)
				NULL::UUID AS chat_user_id,
				'group' AS type,
				m.content,
				m.sender_id,
				m.created_at,
				FALSE AS is_read,
				m.group_id
			FROM messages m
			JOIN group_members gm ON m.group_id = gm.group_id
			WHERE gm.user_id = $1::uuid
			ORDER BY m.group_id, m.created_at DESC)
		),
		dm_unread AS (
			SELECT sender_id, COUNT(*) AS count
			FROM messages
			WHERE receiver_id = $1::uuid AND is_read = FALSE AND group_id IS NULL
			GROUP BY sender_id
		),
		group_unread AS (
			SELECT m.group_id, COUNT(*) AS count
			FROM messages m
			JOIN group_members gm ON m.group_id = gm.group_id
			WHERE gm.user_id = $1::uuid AND m.created_at > gm.last_read_at AND m.sender_id != $1::uuid
			GROUP BY m.group_id
		)
		SELECT 
			COALESCE(rc.chat_user_id::TEXT, rc.group_id::TEXT, '') AS id,
			COALESCE(rc.type, 'direct') AS type,
			COALESCE(u.username, g.name, 'Unknown Channel') AS name,
			COALESCE(u.display_name, '') AS display_name,
			COALESCE(rc.content, '') AS last_message,
			COALESCE(rc.created_at, NOW()) AS last_message_time,
			COALESCE(rc.sender_id::TEXT, '') AS sender_id,
			COALESCE(
				CASE 
					WHEN rc.type = 'direct' THEN rc.is_read
					ELSE (rc.created_at <= gm2.last_read_at)
				END, 
				FALSE
			) AS is_read,
			CASE 
				WHEN rc.type = 'direct' THEN COALESCE(du.count, 0)::INT
				ELSE COALESCE(gu.count, 0)::INT
			END AS unread_count
		FROM raw_conversations rc
		LEFT JOIN users u ON rc.chat_user_id = u.id
		LEFT JOIN groups g ON rc.group_id = g.id
		LEFT JOIN dm_unread du ON rc.chat_user_id = du.sender_id
		LEFT JOIN group_unread gu ON rc.group_id = gu.group_id
		LEFT JOIN group_members gm2 ON gm2.group_id = rc.group_id AND gm2.user_id = $1::uuid
		ORDER BY last_message_time DESC;
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
			&c.ID,
			&c.Type,
			&c.Name,
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

func (r *MessageRepository) UpdateGroupLastRead(ctx context.Context, groupID, userID string) error {
	query := `
		UPDATE group_members 
		SET last_read_at = CURRENT_TIMESTAMP 
		WHERE group_id = $1 AND user_id = $2;
	`
	_, err := config.DB.Exec(ctx, query, groupID, userID)
	return err
}
