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
