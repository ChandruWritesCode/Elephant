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
