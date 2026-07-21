CREATE TABLE IF NOT EXISTS user_devices (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(50) NOT NULL,
    identity_key TEXT NOT NULL,
    signed_prekey TEXT NOT NULL,
    signed_prekey_signature TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, device_id)
);

CREATE TABLE IF NOT EXISTS one_time_prekeys (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    device_id VARCHAR(50) NOT NULL,
    key_id INT NOT NULL,
    key_content TEXT NOT NULL,
    FOREIGN KEY (user_id, device_id) REFERENCES user_devices(user_id, device_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_otp_lookup ON one_time_prekeys(user_id, device_id);