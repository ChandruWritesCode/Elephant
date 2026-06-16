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

func NewUserService(repo *repository.UserRepository) *UserService {
	return &UserService{repo: repo}
}

type CreateUserRequest struct {
	Username    string
	DisplayName string
	Password    string
}

func (s *UserService) CreateUser(ctx context.Context, req CreateUserRequest) (*models.User, error) {
	username := strings.ToLower(strings.TrimSpace(req.Username))
	displayName := strings.TrimSpace(req.DisplayName)

	if username == "" || displayName == "" || req.Password == "" {
		return nil, errors.New("all registration fields are required")
	}

	if len(req.Password) < 8 {
		return nil, errors.New("password length must be 8 or more characters long")
	}

	exists, err := s.repo.UsernameExists(ctx, username)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, errors.New("this username is already taken")
	}

	temporaryHash := "temp_hash_later_to_be_upgraded_using_argon2" + req.Password
	
	userModel, err := s.repo.CreateUser(ctx, username, displayName, temporaryHash)
	if err != nil {
		return nil, err
	}

	return userModel, nil
}