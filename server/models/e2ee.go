package models

type OneTimeKeyReq struct {
	ID      int    `json:"id"`
	Content string `json:"content"`
}

type UploadKeysReq struct {
	DeviceID       string          `json:"device_id"`
	IdentityKey    string          `json:"identity_key"`
	SignedPrekey   string          `json:"signed_prekey"`
	Signature      string          `json:"signature"`
	OneTimePrekeys []OneTimeKeyReq `json:"one_time_prekeys"`
}

type PrekeyBundle struct {
	UserID            string  `json:"user_id"`
	DeviceID          string  `json:"device_id"`
	IdentityKey       string  `json:"identity_key"`
	SignedPrekey      string  `json:"signed_prekey"`
	Signature         string  `json:"signature"`
	OneTimePrekeyID   *int    `json:"one_time_prekey_id,omitempty"`
	OneTimePrekeyBody *string `json:"one_time_prekey_body,omitempty"`
}

type VerifyContactReq struct {
	VerifiedUserID string `json:"verified_user_id"`
	IsVerified     bool   `json:"is_verified"`
}

type VerificationStatusResp struct {
	UserID         string `json:"user_id"`
	VerifiedUserID string `json:"verified_user_id"`
	IsVerified     bool   `json:"is_verified"`
}

type ResetKeysReq struct {
	Password string `json:"password"`
}
