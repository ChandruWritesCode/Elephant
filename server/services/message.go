package services

import (
	"context"
	"errors"
	"strings"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
)

type MessageService struct {
	repo *repository.MessageRepository
}

func NewMessageService() *MessageService {
	return &MessageService{repo: repository.NewMessageRepository()}
}

func (s *MessageService) SendMessage(ctx context.Context, senderID, receiverID, content, replyToMessageID string) (*models.Message, error) {
	content = strings.TrimSpace(content)
	if content == "" {
		return nil, errors.New("message content cannot be empty")
	}
	if senderID == receiverID {
		return nil, errors.New("cannot send a message to yourself")
	}
	return s.repo.CreateMessage(ctx, senderID, receiverID, content, replyToMessageID)
}
