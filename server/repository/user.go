package repository

import (
	"context"
	"errors"

	"github.com/commandlinecoding/elephant/server/config"
	"github.com/commandlinecoding/elephant/server/models"
	"github.com/jackc/pgx/v5"
)

type UserRepository struct{}

func NewUserRepository() *UserRepository {
	return &UserRepository{}
}

func (r *UserRepository) CreateUser(ctx context.Context, username, displayName, passwordHash string) (*models.User, error) {
	query := `
		INSERT INTO users (username, display_name, password_hash, created_at)
		VALUES ($1, $2, $3, NOW())
		RETURNING id, username, display_name, password_hash, created_at;
	`

	var user models.User

	err := config.DB.QueryRow(ctx, query, username, displayName, passwordHash).Scan(
		&user.ID,
		&user.Username,
		&user.DisplayName,
		&user.PasswordHash,
		&user.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) UsernameExists(ctx context.Context, username string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE username = $1);`

	var exists bool
	err := config.DB.QueryRow(ctx, query, username).Scan(&exists)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return false, err
	}

	return exists, nil
}
