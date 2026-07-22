package repository

import (
	"context"
	"errors"

	"github.com/commandlinecoding/elephant/server/config"
	"github.com/commandlinecoding/elephant/server/models"
	"github.com/jackc/pgx/v5"
)

type E2EERepository struct{}

func NewE2EERepository() *E2EERepository {
	return &E2EERepository{}
}

func (r *E2EERepository) SaveDeviceKeys(ctx context.Context, uid string, req models.UploadKeysReq) error {
	tx, err := config.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var existingKey string
	checkQuery := `SELECT identity_key FROM user_devices WHERE user_id = $1::uuid AND device_id = $2;`
	_ = tx.QueryRow(ctx, checkQuery, uid, req.DeviceID).Scan(&existingKey)

	deviceQuery := `
		INSERT INTO user_devices (user_id, device_id, identity_key, signed_prekey, signed_prekey_signature, updated_at)
		VALUES ($1::uuid, $2, $3, $4, $5, NOW())
		ON CONFLICT (user_id, device_id) 
		DO UPDATE SET identity_key = $3, signed_prekey = $4, signed_prekey_signature = $5, updated_at = NOW();
	`
	_, err = tx.Exec(ctx, deviceQuery, uid, req.DeviceID, req.IdentityKey, req.SignedPrekey, req.Signature)
	if err != nil {
		return err
	}

	if existingKey != req.IdentityKey {
		invalidateQuery := `
			UPDATE user_verifications 
			SET is_verified = FALSE, updated_at = NOW() 
			WHERE verified_user_id = $1::uuid;
		`
		_, err = tx.Exec(ctx, invalidateQuery, uid)
		if err != nil {
			return err
		}
	}

	if len(req.OneTimePrekeys) > 0 {
		otpQuery := `INSERT INTO one_time_prekeys (user_id, device_id, key_id, key_content) VALUES ($1::uuid, $2, $3, $4);`
		for _, k := range req.OneTimePrekeys {
			_, err = tx.Exec(ctx, otpQuery, uid, req.DeviceID, k.ID, k.Content)
			if err != nil {
				return err
			}
		}
	}

	return tx.Commit(ctx)
}

func (r *E2EERepository) FetchBundle(ctx context.Context, targetUID, deviceID string) (*models.PrekeyBundle, error) {
	tx, err := config.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	baseQuery := `
		SELECT identity_key, signed_prekey, signed_prekey_signature 
		FROM user_devices 
		WHERE user_id = $1::uuid AND device_id = $2;
	`
	var b models.PrekeyBundle
	b.UserID = targetUID
	b.DeviceID = deviceID

	err = tx.QueryRow(ctx, baseQuery, targetUID, deviceID).Scan(&b.IdentityKey, &b.SignedPrekey, &b.Signature)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("device keys not found for target identity profile")
		}
		return nil, err
	}

	otpQuery := `
		DELETE FROM one_time_prekeys 
		WHERE id = (
			SELECT id FROM one_time_prekeys 
			WHERE user_id = $1::uuid AND device_id = $2 
			LIMIT 1
		) 
		RETURNING key_id, key_content;
	`
	var otpID int
	var otpBody string
	err = tx.QueryRow(ctx, otpQuery, targetUID, deviceID).Scan(&otpID, &otpBody)
	if err == nil {
		b.OneTimePrekeyID = &otpID
		b.OneTimePrekeyBody = &otpBody
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &b, nil
}

func (r *E2EERepository) GetOTPCount(ctx context.Context, uid, deviceID string) (int, error) {
	query := `SELECT COUNT(*) FROM one_time_prekeys WHERE user_id = $1::uuid AND device_id = $2;`
	var count int
	err := config.DB.QueryRow(ctx, query, uid, deviceID).Scan(&count)
	return count, err
}

func (r *E2EERepository) SetVerificationStatus(ctx context.Context, uid, targetUID string, isVerified bool) error {
	query := `
		INSERT INTO user_verifications (user_id, verified_user_id, is_verified, updated_at)
		VALUES ($1::uuid, $2::uuid, $3, NOW())
		ON CONFLICT (user_id, verified_user_id)
		DO UPDATE SET is_verified = $3, updated_at = NOW();
	`
	_, err := config.DB.Exec(ctx, query, uid, targetUID, isVerified)
	return err
}

func (r *E2EERepository) GetVerificationStatus(ctx context.Context, uid, targetUID string) (bool, error) {
	query := `
		SELECT is_verified 
		FROM user_verifications 
		WHERE user_id = $1::uuid AND verified_user_id = $2::uuid;
	`
	var isVerified bool
	err := config.DB.QueryRow(ctx, query, uid, targetUID).Scan(&isVerified)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}
	return isVerified, nil
}

func (r *E2EERepository) InvalidateUserVerifications(ctx context.Context, uid string) error {
	query := `
		UPDATE user_verifications 
		SET is_verified = FALSE, updated_at = NOW() 
		WHERE verified_user_id = $1::uuid;
	`
	_, err := config.DB.Exec(ctx, query, uid)
	return err
}

func (r *E2EERepository) ResetUserKeys(ctx context.Context, uid string) error {
	tx, err := config.DB.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `DELETE FROM user_devices WHERE user_id = $1::uuid;`, uid)
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx, `DELETE FROM one_time_prekeys WHERE user_id = $1::uuid;`, uid)
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx, `
		UPDATE user_verifications 
		SET is_verified = FALSE, updated_at = NOW() 
		WHERE verified_user_id = $1::uuid;
	`, uid)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}
