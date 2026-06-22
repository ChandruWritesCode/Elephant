package services

import (
	"context"
	"errors"
	"strings"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
)

type AuthService struct {
	repo *repository.UserRepository
}

func NewAuthService() *AuthService {
	return &AuthService{repo: repository.NewUserRepository()}
}

func (s *AuthService) Login(ctx context.Context, username, password string) (*models.User, *TokenPair, error) {
	username = strings.ToLower(strings.TrimSpace(username))

	user, err := s.repo.FindByUsername(ctx, username)
	if err != nil {
		return nil, nil, errors.New("invalid username or password credentials")
	}

	match, err := VerifyPassword(password, user.PasswordHash)
	if err != nil || !match {
		return nil, nil, errors.New("invalid username or password credentials")
	}

	tokens, err := GenerateTokenPair(user.ID)
	if err != nil {
		return nil, nil, errors.New("failed to issue tokens")
	}

	return user, tokens, nil
}