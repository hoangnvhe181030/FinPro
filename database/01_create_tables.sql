-- ============================================================================
-- OracleSQL Auction System - Table Creation Script
-- ============================================================================
-- Description: Creates all tables for English Auction system with Kafka integration
-- Features: Soft-close, Wallet deposits, Read-heavy optimization
-- Author: Database Architect
-- Date: 2026-01-20
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
CREATE TABLE users (
    user_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR2(50) NOT NULL UNIQUE,
    email           VARCHAR2(100) NOT NULL UNIQUE,
    password_hash   VARCHAR2(255) NOT NULL,
    full_name       VARCHAR2(100),
    phone_number    VARCHAR2(20),
    status          VARCHAR2(20) DEFAULT 'ACTIVE' 
                    CHECK (status IN ('ACTIVE', 'INACTIVE', 'BANNED')),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE users IS 'User accounts for buyers and sellers';
COMMENT ON COLUMN users.status IS 'User account status: ACTIVE, INACTIVE, or BANNED';

-- ============================================================================
-- 2. WALLETS TABLE (Optimistic Locking)
-- ============================================================================
CREATE TABLE wallets (
    wallet_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          NUMBER NOT NULL UNIQUE,
    balance          NUMBER(15,2) DEFAULT 0 CHECK (balance >= 0),
    reserved_balance NUMBER(15,2) DEFAULT 0 CHECK (reserved_balance >= 0),
    currency         VARCHAR2(10) DEFAULT 'VND',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    version          NUMBER DEFAULT 0 NOT NULL,
    CONSTRAINT fk_wallets_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_wallet_balance CHECK (balance >= reserved_balance)
);

COMMENT ON TABLE wallets IS 'User wallet balances with optimistic locking';
COMMENT ON COLUMN wallets.balance IS 'Total available balance';
COMMENT ON COLUMN wallets.reserved_balance IS 'Amount locked for active bids';
COMMENT ON COLUMN wallets.version IS 'Optimistic lock version for concurrency control';

-- ============================================================================
-- 3. CATEGORIES TABLE (Hierarchical)
-- ============================================================================
CREATE TABLE categories (
    category_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name      VARCHAR2(100) NOT NULL UNIQUE,
    description        VARCHAR2(500),
    parent_category_id NUMBER,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) 
        REFERENCES categories(category_id) ON DELETE SET NULL
);

COMMENT ON TABLE categories IS 'Product categories with hierarchical support';

-- ============================================================================
-- 4. PRODUCTS TABLE
-- ============================================================================
CREATE TABLE products (
    product_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id  NUMBER NOT NULL,
    product_name VARCHAR2(200) NOT NULL,
    description  CLOB,
    condition    VARCHAR2(20) 
                 CHECK (condition IN ('NEW', 'LIKE_NEW', 'GOOD', 'FAIR', 'POOR')),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) 
        REFERENCES categories(category_id) ON DELETE CASCADE
);

COMMENT ON TABLE products IS 'Products available for auction';
COMMENT ON COLUMN products.condition IS 'Physical condition of the product';

-- ============================================================================
-- 5. AUCTIONS TABLE (Core Auction Management)
-- ============================================================================
CREATE TABLE auctions (
    auction_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id         NUMBER NOT NULL,
    seller_id          NUMBER NOT NULL,
    winner_id          NUMBER,
    starting_price     NUMBER(15,2) NOT NULL CHECK (starting_price >= 0),
    current_price      NUMBER(15,2) NOT NULL,
    reserve_price      NUMBER(15,2),
    bid_increment      NUMBER(15,2) DEFAULT 10000 CHECK (bid_increment > 0),
    start_time         TIMESTAMP NOT NULL,
    end_time           TIMESTAMP NOT NULL,
    original_end_time  TIMESTAMP NOT NULL,
    status             VARCHAR2(20) DEFAULT 'PENDING' 
                       CHECK (status IN ('PENDING', 'ACTIVE', 'ENDED', 'CANCELLED', 'SETTLED')),
    total_bids         NUMBER DEFAULT 0,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    version            NUMBER DEFAULT 0 NOT NULL,
    CONSTRAINT fk_auctions_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_auctions_seller FOREIGN KEY (seller_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_auctions_winner FOREIGN KEY (winner_id) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_auction_times CHECK (end_time > start_time),
    CONSTRAINT chk_current_price CHECK (current_price >= starting_price)
);

COMMENT ON TABLE auctions IS 'Auction listings with soft-close support';
COMMENT ON COLUMN auctions.original_end_time IS 'Initial end time before soft-close extensions';
COMMENT ON COLUMN auctions.bid_increment IS 'Minimum bid increment (default 10,000 VND)';
COMMENT ON COLUMN auctions.version IS 'Optimistic lock for soft-close race prevention';

-- ============================================================================
-- 6. BIDS TABLE (Immutable Event Log)
-- ============================================================================
CREATE TABLE bids (
    bid_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    auction_id  NUMBER NOT NULL,
    user_id     NUMBER NOT NULL,
    bid_amount  NUMBER(15,2) NOT NULL CHECK (bid_amount > 0),
    bid_status  VARCHAR2(20) DEFAULT 'PENDING' 
                CHECK (bid_status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'OUTBID')),
    bid_time    TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    client_ip   VARCHAR2(45),
    version     NUMBER DEFAULT 0,
    CONSTRAINT fk_bids_auction FOREIGN KEY (auction_id) 
        REFERENCES auctions(auction_id) ON DELETE CASCADE,
    CONSTRAINT fk_bids_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE
);

COMMENT ON TABLE bids IS 'Immutable bid history (event sourcing - never UPDATE/DELETE)';
COMMENT ON COLUMN bids.bid_status IS 'Lifecycle: PENDING -> ACCEPTED/REJECTED -> OUTBID';
COMMENT ON COLUMN bids.client_ip IS 'Client IP for audit trail';

-- ============================================================================
-- 7. WALLET_TRANSACTIONS TABLE (Audit Trail)
-- ============================================================================
CREATE TABLE wallet_transactions (
    transaction_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    wallet_id        NUMBER NOT NULL,
    user_id          NUMBER NOT NULL,
    auction_id       NUMBER,
    transaction_type VARCHAR2(30) 
                     CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAW', 'BID_RESERVE', 
                                                  'BID_RELEASE', 'PAYMENT', 'REFUND', 'PAYOUT')),
    amount           NUMBER(15,2) NOT NULL,
    balance_before   NUMBER(15,2) NOT NULL,
    balance_after    NUMBER(15,2) NOT NULL,
    status           VARCHAR2(20) DEFAULT 'COMPLETED' 
                     CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
    description      VARCHAR2(500),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_wt_wallet FOREIGN KEY (wallet_id) 
        REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    CONSTRAINT fk_wt_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_wt_auction FOREIGN KEY (auction_id) 
        REFERENCES auctions(auction_id) ON DELETE SET NULL
);

COMMENT ON TABLE wallet_transactions IS 'Immutable financial audit trail (never UPDATE/DELETE)';
COMMENT ON COLUMN wallet_transactions.balance_before IS 'Snapshot of balance before transaction';
COMMENT ON COLUMN wallet_transactions.balance_after IS 'Snapshot of balance after transaction';

-- ============================================================================
-- 8. AUCTION_EVENTS TABLE (Auction State Changes)
-- ============================================================================
CREATE TABLE auction_events (
    event_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    auction_id  NUMBER NOT NULL,
    event_type  VARCHAR2(50) 
                CHECK (event_type IN ('CREATED', 'STARTED', 'BID_PLACED', 
                                      'SOFT_CLOSE_EXTENDED', 'ENDED', 'SETTLED', 'CANCELLED')),
    event_data  CLOB,
    event_time  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processed   CHAR(1) DEFAULT 'N' CHECK (processed IN ('Y', 'N')),
    CONSTRAINT fk_ae_auction FOREIGN KEY (auction_id) 
        REFERENCES auctions(auction_id) ON DELETE CASCADE
);

COMMENT ON TABLE auction_events IS 'Auction state change events for Kafka publishing';
COMMENT ON COLUMN auction_events.event_data IS 'JSON payload with event details';

-- ============================================================================
-- 9. BID_EVENTS TABLE (Bid Processing Events)
-- ============================================================================
CREATE TABLE bid_events (
    event_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bid_id      NUMBER NOT NULL,
    auction_id  NUMBER NOT NULL,
    user_id     NUMBER NOT NULL,
    event_type  VARCHAR2(50) 
                CHECK (event_type IN ('BID_RECEIVED', 'BID_VALIDATED', 
                                      'BID_ACCEPTED', 'BID_REJECTED', 'BID_OUTBID')),
    event_data  CLOB,
    event_time  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processed   CHAR(1) DEFAULT 'N' CHECK (processed IN ('Y', 'N')),
    CONSTRAINT fk_be_bid FOREIGN KEY (bid_id) 
        REFERENCES bids(bid_id) ON DELETE CASCADE,
    CONSTRAINT fk_be_auction FOREIGN KEY (auction_id) 
        REFERENCES auctions(auction_id) ON DELETE CASCADE,
    CONSTRAINT fk_be_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE
);

COMMENT ON TABLE bid_events IS 'Bid lifecycle events for Kafka consumption';

-- ============================================================================
-- 10. OUTBOX TABLE (Transactional Outbox Pattern)
-- ============================================================================
CREATE TABLE outbox (
    outbox_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    aggregate_type VARCHAR2(50) NOT NULL,
    aggregate_id   NUMBER NOT NULL,
    event_type     VARCHAR2(100) NOT NULL,
    payload        CLOB NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    published      CHAR(1) DEFAULT 'N' CHECK (published IN ('Y', 'N')),
    published_at   TIMESTAMP
);

COMMENT ON TABLE outbox IS 'Transactional outbox for atomic DB writes + Kafka publish';
COMMENT ON COLUMN outbox.aggregate_type IS 'Entity type: AUCTION, BID, WALLET';
COMMENT ON COLUMN outbox.payload IS 'JSON event payload to publish to Kafka';

-- ============================================================================
-- All 10 tables created successfully
-- Tables: users, wallets, categories, products, auctions, bids,
--         wallet_transactions, auction_events, bid_events, outbox
-- ============================================================================
