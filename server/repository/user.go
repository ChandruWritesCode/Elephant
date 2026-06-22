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

func (r *UserRepository) FindByUsername(ctx context.Context, username string) (*models.User, error) {
	query := `
		SELECT id, username, display_name, password_hash, created_at 
		FROM users 
		WHERE username = $1;
	`
	var user models.User
	err := config.DB.QueryRow(ctx, query, username).Scan(
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

func (r *UserRepository) SearchUsers(ctx context.Context, searchTerm string, limit, offset int) ([]models.User, error) {
	pattern := "%" + searchTerm + "%"

	query := `
		SELECT id, username, display_name, created_at
		FROM users
		WHERE username ILIKE $1 OR display_name ILIKE $2
		ORDER BY username ASC
		LIMIT $3 OFFSET $4;
	`

	rows, err := config.DB.Query(ctx, query, pattern, pattern, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []models.User = []models.User{}
	for rows.Next() {
		var u models.User
		err := rows.Scan(&u.ID, &u.Username, &u.DisplayName, &u.CreatedAt)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return users, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	query := `
		SELECT id, username, display_name, created_at 
		FROM users 
		WHERE id = $1;
	`
	var user models.User
	err := config.DB.QueryRow(ctx, query, id).Scan(
		&user.ID,
		&user.Username,
		&user.DisplayName,
		&user.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &user, nil
}