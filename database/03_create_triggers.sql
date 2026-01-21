-- ============================================================================
-- OracleSQL Auction System - Trigger Creation Script
-- ============================================================================
-- Description: Auto-update triggers for updated_at and version columns
-- Date: 2026-01-20
-- ============================================================================

-- ============================================================================
-- USERS TABLE TRIGGER
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- ============================================================================
-- WALLETS TABLE TRIGGER (with Version Increment)
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
    :NEW.version := :OLD.version + 1;
END;
/

-- ============================================================================
-- AUCTIONS TABLE TRIGGER (with Version Increment)
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_auctions_updated_at
BEFORE UPDATE ON auctions
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
    :NEW.version := :OLD.version + 1;
END;
/

-- ============================================================================
-- All triggers created successfully
-- Auto-update triggers: users.updated_at, wallets.updated_at + version,
--                       auctions.updated_at + version
-- ============================================================================
