package services

import (
	"context"
	"errors"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
)

type E2EEService struct {
	repo *repository.E2EERepository
}

func NewE2EEService() *E2EEService {
	return &E2EEService{repo: repository.NewE2EERepository()}
}

func (s *E2EEService) UploadKeys(ctx context.Context, uid string, req models.UploadKeysReq) error {
	if req.DeviceID == "" || req.IdentityKey == "" || req.SignedPrekey == "" || req.Signature == "" {
		return errors.New("missing core payload parameters for prekey bundle submission")
	}
	return s.repo.SaveDeviceKeys(ctx, uid, req)
}

func (s *E2EEService) GetBundle(ctx context.Context, targetUID, deviceID string) (*models.PrekeyBundle, error) {
	if deviceID == "" {
		deviceID = "main"
	}
	return s.repo.FetchBundle(ctx, targetUID, deviceID)
}

func (s *E2EEService) CheckKeysExhaustion(ctx context.Context, uid string, deviceID string) (int, bool, error) {
	count, err := s.repo.GetOTPCount(ctx, uid, deviceID)
	if err != nil {
		return 0, false, err
	}
	return count, count < 10, nil
}
