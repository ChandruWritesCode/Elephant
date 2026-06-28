CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS group_members (
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id)
);

-- Optimize message query routing for group contexts
ALTER TABLE messages ADD COLUMN group_id UUID REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE messages ALTER COLUMN receiver_id DROP NOT NULL; -- Can be null if it's a group broadcast

CREATE INDEX IF NOT EXISTS idx_messages_group ON messages(group_id) WHERE group_id IS NOT NULL;