ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(receiver_id, is_read);