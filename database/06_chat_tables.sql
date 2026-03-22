-- ============================================================================
-- OracleSQL Auction System - Chat Messages Table
-- ============================================================================
-- Description: Stores direct messages between users
-- Date: 2026-03-23
-- ============================================================================

CREATE TABLE chat_messages (
    message_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_id    NUMBER NOT NULL,
    receiver_id  NUMBER NOT NULL,
    content      VARCHAR2(2000) NOT NULL,
    is_read      CHAR(1) DEFAULT 'N' CHECK (is_read IN ('Y', 'N')),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_chat_sender FOREIGN KEY (sender_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_receiver FOREIGN KEY (receiver_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_chat_different_users CHECK (sender_id != receiver_id)
);

COMMENT ON TABLE chat_messages IS 'Direct messages between users';

-- Index for fetching conversation between two users
CREATE INDEX idx_chat_conversation ON chat_messages (
    LEAST(sender_id, receiver_id),
    GREATEST(sender_id, receiver_id),
    created_at DESC
);

-- Index for fetching unread messages for a user
CREATE INDEX idx_chat_unread ON chat_messages (receiver_id, is_read);

-- ============================================================================
-- Chat messages table created successfully
-- ============================================================================
