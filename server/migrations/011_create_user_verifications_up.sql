CREATE TABLE IF NOT EXISTS user_verifications (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    verified_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    is_verified BOOLEAN DEFAULT TRUE NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, verified_user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_verifications ON user_verifications(user_id, verified_user_id);