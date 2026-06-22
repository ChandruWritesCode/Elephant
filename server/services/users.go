package services

import (
	"context"
	"errors"
	"strings"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
)

type UserService struct {
	repo *repository.UserRepository
}

func NewUserService() *UserService {
	return &UserService{repo: repository.NewUserRepository()}
}

func (s *UserService) Register(ctx context.Context, un, dn, passwd string) (*models.User, error) {
	un = strings.ToLower(strings.TrimSpace(un))
	dn = strings.TrimSpace(dn)

	if len(un) < 3 || len(un) > 30 {
		return nil, errors.New("username must be between 3 and 30 characters")
	}
	if len(passwd) < 8 {
		return nil, errors.New("password must be at least 8 characters long")
	}
	if dn == "" {
		return nil, errors.New("display name cannot be empty")
	}

	exists, err := s.repo.UsernameExists(ctx, un)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, errors.New("username is already taken")
	}

	hash, err := HashPassword(passwd)
	if err != nil {
		return nil, err
	}

	return s.repo.CreateUser(ctx, un, dn, hash)
}