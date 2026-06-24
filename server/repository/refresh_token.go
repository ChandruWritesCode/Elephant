package repository

import (
	"context"
	"time"

	"github.com/commandlinecoding/elephant/server/config"
)

type RefreshTokenRepository struct{}

func NewRefreshTokenRepository() *RefreshTokenRepository {
	return &RefreshTokenRepository{}
}

func (r *RefreshTokenRepository) StoreToken(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error {
	query := `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3);
	`
	_, err := config.DB.Exec(ctx, query, userID, tokenHash, expiresAt)
	return err
}

func (r *RefreshTokenRepository) DeleteToken(ctx context.Context, tokenHash string) error {
	query := `DELETE FROM refresh_tokens WHERE token_hash = $1;`
	_, err := config.DB.Exec(ctx, query, tokenHash)
	return err
}

func (r *RefreshTokenRepository) GetValidTokenUser(ctx context.Context, tokenHash string) (string, error) {
	query := `
		SELECT user_id FROM refresh_tokens 
		WHERE token_hash = $1 AND expires_at > NOW();
	`
	var userID string
	err := config.DB.QueryRow(ctx, query, tokenHash).Scan(&userID)
	if err != nil {
		return "", err
	}
	return userID, nil
}