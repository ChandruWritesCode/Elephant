ALTER TABLE group_members ADD COLUMN last_read_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_group_members_read_tracking ON group_members(group_id, user_id, last_read_at);