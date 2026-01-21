-- ============================================================================
-- OracleSQL Auction System - Sample Data Script
-- ============================================================================
-- Description: Inserts test data for development and testing
-- WARNING: DO NOT run in production!
-- Date: 2026-01-20
-- ============================================================================

-- ============================================================================
-- 1. SAMPLE USERS
-- ============================================================================
INSERT INTO users (username, email, password_hash, full_name, phone_number, status)
VALUES ('john_doe', 'john@example.com', '$2a$10$hash123', 'John Doe', '0901234567', 'ACTIVE');

INSERT INTO users (username, email, password_hash, full_name, phone_number, status)
VALUES ('jane_smith', 'jane@example.com', '$2a$10$hash456', 'Jane Smith', '0907654321', 'ACTIVE');

INSERT INTO users (username, email, password_hash, full_name, phone_number, status)
VALUES ('seller_pro', 'seller@example.com', '$2a$10$hash789', 'Pro Seller', '0909876543', 'ACTIVE');

-- ============================================================================
-- 2. SAMPLE WALLETS
-- ============================================================================
INSERT INTO wallets (user_id, balance, reserved_balance, currency)
VALUES (1, 50000000, 0, 'VND'); -- John has 50M VND

INSERT INTO wallets (user_id, balance, reserved_balance, currency)
VALUES (2, 30000000, 0, 'VND'); -- Jane has 30M VND

INSERT INTO wallets (user_id, balance, reserved_balance, currency)
VALUES (3, 10000000, 0, 'VND'); -- Seller has 10M VND

-- ============================================================================
-- 3. SAMPLE CATEGORIES
-- ============================================================================
INSERT INTO categories (category_name, description)
VALUES ('Electronics', 'Electronic devices and gadgets');

INSERT INTO categories (category_name, description, parent_category_id)
VALUES ('Smartphones', 'Mobile phones', 1);

INSERT INTO categories (category_name, description, parent_category_id)
VALUES ('Laptops', 'Portable computers', 1);

INSERT INTO categories (category_name, description)
VALUES ('Fashion', 'Clothing and accessories');

INSERT INTO categories (category_name, description)
VALUES ('Home & Garden', 'Home improvement and gardening');

-- ============================================================================
-- 4. SAMPLE PRODUCTS
-- ============================================================================
INSERT INTO products (category_id, product_name, description, condition)
VALUES (2, 'iPhone 15 Pro Max 256GB', 'Brand new, sealed box, Titanium Blue', 'NEW');

INSERT INTO products (category_id, product_name, description, condition)
VALUES (2, 'Samsung Galaxy S24 Ultra', 'Used 3 months, excellent condition', 'LIKE_NEW');

INSERT INTO products (category_id, product_name, description, condition)
VALUES (3, 'MacBook Pro M3 14-inch', 'Brand new, AppleCare+ included', 'NEW');

INSERT INTO products (category_id, product_name, description, condition)
VALUES (4, 'Vintage Leather Jacket', 'Genuine leather, size M', 'GOOD');

-- ============================================================================
-- 5. SAMPLE AUCTIONS
-- ============================================================================
-- Active auction starting now, ending in 2 hours
INSERT INTO auctions (
    product_id, seller_id, starting_price, current_price, reserve_price,
    bid_increment, start_time, end_time, original_end_time, status
) VALUES (
    1, 3, 20000000, 20000000, 25000000, 10000,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '2' HOUR,
    CURRENT_TIMESTAMP + INTERVAL '2' HOUR,
    'ACTIVE'
);

-- Active auction ending soon (for soft-close testing)
INSERT INTO auctions (
    product_id, seller_id, starting_price, current_price, reserve_price,
    bid_increment, start_time, end_time, original_end_time, status
) VALUES (
    2, 3, 15000000, 16000000, 18000000, 10000,
    CURRENT_TIMESTAMP - INTERVAL '1' HOUR,
    CURRENT_TIMESTAMP + INTERVAL '3' MINUTE,
    CURRENT_TIMESTAMP + INTERVAL '3' MINUTE,
    'ACTIVE'
);

-- Pending auction (starts tomorrow)
INSERT INTO auctions (
    product_id, seller_id, starting_price, current_price, reserve_price,
    bid_increment, start_time, end_time, original_end_time, status
) VALUES (
    3, 3, 30000000, 30000000, 35000000, 10000,
    CURRENT_TIMESTAMP + INTERVAL '1' DAY,
    CURRENT_TIMESTAMP + INTERVAL '1' DAY + INTERVAL '3' HOUR,
    CURRENT_TIMESTAMP + INTERVAL '1' DAY + INTERVAL '3' HOUR,
    'PENDING'
);

-- ============================================================================
-- 6. SAMPLE BIDS
-- ============================================================================
-- Bid on auction 1
INSERT INTO bids (auction_id, user_id, bid_amount, bid_status, bid_time, client_ip)
VALUES (1, 1, 20010000, 'ACCEPTED', CURRENT_TIMESTAMP - INTERVAL '30' MINUTE, '192.168.1.100');

INSERT INTO bids (auction_id, user_id, bid_amount, bid_status, bid_time, client_ip)
VALUES (1, 2, 20020000, 'ACCEPTED', CURRENT_TIMESTAMP - INTERVAL '25' MINUTE, '192.168.1.101');

-- Bid on auction 2
INSERT INTO bids (auction_id, user_id, bid_amount, bid_status, bid_time, client_ip)
VALUES (2, 1, 15010000, 'OUTBID', CURRENT_TIMESTAMP - INTERVAL '20' MINUTE, '192.168.1.100');

INSERT INTO bids (auction_id, user_id, bid_amount, bid_status, bid_time, client_ip)
VALUES (2, 2, 16000000, 'ACCEPTED', CURRENT_TIMESTAMP - INTERVAL '10' MINUTE, '192.168.1.101');

-- ============================================================================
-- 7. SAMPLE WALLET TRANSACTIONS
-- ============================================================================
-- John's deposit
INSERT INTO wallet_transactions (
    wallet_id, user_id, auction_id, transaction_type, amount,
    balance_before, balance_after, status, description
) VALUES (
    1, 1, NULL, 'DEPOSIT', 50000000,
    0, 50000000, 'COMPLETED', 'Initial deposit'
);

-- Jane's deposit
INSERT INTO wallet_transactions (
    wallet_id, user_id, auction_id, transaction_type, amount,
    balance_before, balance_after, status, description
) VALUES (
    2, 2, NULL, 'DEPOSIT', 30000000,
    0, 30000000, 'COMPLETED', 'Initial deposit'
);

-- ============================================================================
-- 8. UPDATE AUCTION STATISTICS
-- ============================================================================
UPDATE auctions SET total_bids = 2, current_price = 20020000 WHERE auction_id = 1;
UPDATE auctions SET total_bids = 2, current_price = 16000000 WHERE auction_id = 2;

-- ============================================================================
-- All sample data inserted successfully
-- To verify, run:
--   SELECT COUNT(*) FROM users;      -- Should return 3
--   SELECT COUNT(*) FROM auctions;   -- Should return 3
--   SELECT COUNT(*) FROM bids;       -- Should return 4
-- ============================================================================
