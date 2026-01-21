-- ============================================================================
-- OracleSQL Auction System - Soft-Close Function
-- ============================================================================
-- Description: Implements soft-close mechanism (5-minute extension rule)
-- Rule: If bid placed within 5 minutes of end_time, extend by 5 minutes
-- Usage: Called by Spring Boot service after bid validation
-- Date: 2026-01-20
-- ============================================================================

-- ============================================================================
-- FUNCTION: check_and_extend_auction
-- ============================================================================
-- Purpose: Check if auction needs soft-close extension and apply it
-- Parameters:
--   p_auction_id: The auction to check
--   p_bid_time: When the bid was placed
-- Returns: 
--   1 if auction was extended
--   0 if no extension needed
-- Side Effects:
--   - Updates auctions.end_time if extension triggered
--   - Inserts event into auction_events
--   - Inserts event into outbox for Kafka
-- ============================================================================

CREATE OR REPLACE FUNCTION check_and_extend_auction(
    p_auction_id IN NUMBER,
    p_bid_time IN TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURN NUMBER
IS
    v_end_time TIMESTAMP;
    v_time_remaining NUMBER; -- in seconds
    v_extended NUMBER := 0;
    v_extension_count NUMBER;
BEGIN
    -- Lock the auction row to prevent concurrent extensions
    SELECT end_time INTO v_end_time
    FROM auctions
    WHERE auction_id = p_auction_id
    AND status = 'ACTIVE'
    FOR UPDATE NOWAIT;
    
    -- Calculate time remaining in seconds
    v_time_remaining := EXTRACT(DAY FROM (v_end_time - p_bid_time)) * 86400
                      + EXTRACT(HOUR FROM (v_end_time - p_bid_time)) * 3600
                      + EXTRACT(MINUTE FROM (v_end_time - p_bid_time)) * 60
                      + EXTRACT(SECOND FROM (v_end_time - p_bid_time));
    
    -- If bid placed in last 5 minutes (300 seconds), extend by 5 minutes
    IF v_time_remaining > 0 AND v_time_remaining <= 300 THEN
        
        -- Extend end_time by 5 minutes
        UPDATE auctions
        SET end_time = end_time + INTERVAL '5' MINUTE
        WHERE auction_id = p_auction_id;
        
        -- Count how many times this auction has been extended
        SELECT COUNT(*) INTO v_extension_count
        FROM auction_events
        WHERE auction_id = p_auction_id
        AND event_type = 'SOFT_CLOSE_EXTENDED';
        
        -- Log extension event
        INSERT INTO auction_events (
            auction_id,
            event_type,
            event_data
        ) VALUES (
            p_auction_id,
            'SOFT_CLOSE_EXTENDED',
            JSON_OBJECT(
                'extended_by_minutes' VALUE 5,
                'trigger_bid_time' VALUE TO_CHAR(p_bid_time, 'YYYY-MM-DD HH24:MI:SS'),
                'new_end_time' VALUE TO_CHAR(v_end_time + INTERVAL '5' MINUTE, 'YYYY-MM-DD HH24:MI:SS'),
                'time_remaining_seconds' VALUE v_time_remaining,
                'extension_count' VALUE (v_extension_count + 1)
            )
        );
        
        -- Publish to Kafka via outbox pattern
        INSERT INTO outbox (
            aggregate_type,
            aggregate_id,
            event_type,
            payload
        ) VALUES (
            'AUCTION',
            p_auction_id,
            'SOFT_CLOSE_EXTENDED',
            JSON_OBJECT(
                'auction_id' VALUE p_auction_id,
                'extended_by_minutes' VALUE 5,
                'new_end_time' VALUE TO_CHAR(v_end_time + INTERVAL '5' MINUTE, 'YYYY-MM-DD HH24:MI:SS'),
                'extension_count' VALUE (v_extension_count + 1)
            )
        );
        
        v_extended := 1;
        
        COMMIT;
    END IF;
    
    RETURN v_extended;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Auction not found or not active
        RETURN 0;
    WHEN OTHERS THEN
        ROLLBACK;
        -- Re-raise the exception
        RAISE;
END check_and_extend_auction;
/

-- ============================================================================
-- FUNCTION: get_auction_time_remaining
-- ============================================================================
-- Purpose: Calculate time remaining in auction (in seconds)
-- Parameters:
--   p_auction_id: The auction to check
-- Returns: Seconds remaining (negative if expired)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_auction_time_remaining(
    p_auction_id IN NUMBER
) RETURN NUMBER
IS
    v_end_time TIMESTAMP;
    v_time_remaining NUMBER;
BEGIN
    SELECT end_time INTO v_end_time
    FROM auctions
    WHERE auction_id = p_auction_id;
    
    v_time_remaining := EXTRACT(DAY FROM (v_end_time - CURRENT_TIMESTAMP)) * 86400
                      + EXTRACT(HOUR FROM (v_end_time - CURRENT_TIMESTAMP)) * 3600
                      + EXTRACT(MINUTE FROM (v_end_time - CURRENT_TIMESTAMP)) * 60
                      + EXTRACT(SECOND FROM (v_end_time - CURRENT_TIMESTAMP));
    
    RETURN v_time_remaining;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_auction_time_remaining;
/

-- ============================================================================
-- TEST EXAMPLES (Commented Out - Remove comments to test)
-- ============================================================================

/*
-- Test 1: Create test auction ending in 3 minutes
INSERT INTO users (username, email, password_hash, full_name) 
VALUES ('testseller', 'seller@test.com', 'hash123', 'Test Seller');

INSERT INTO categories (category_name, description) 
VALUES ('Electronics', 'Electronic devices');

INSERT INTO products (category_id, product_name, description, condition) 
VALUES (1, 'iPhone 15', 'Brand new iPhone', 'NEW');

INSERT INTO auctions (
    product_id, seller_id, starting_price, current_price, 
    bid_increment, start_time, end_time, original_end_time, status
) VALUES (
    1, 1, 10000000, 10000000, 10000,
    CURRENT_TIMESTAMP, 
    CURRENT_TIMESTAMP + INTERVAL '3' MINUTE,
    CURRENT_TIMESTAMP + INTERVAL '3' MINUTE,
    'ACTIVE'
);

-- Test 2: Simulate bid in last 5 minutes
DECLARE
    v_extended NUMBER;
BEGIN
    v_extended := check_and_extend_auction(
        p_auction_id => 1,
        p_bid_time => CURRENT_TIMESTAMP
    );
    
    IF v_extended = 1 THEN
        DBMS_OUTPUT.PUT_LINE('✅ Auction extended by 5 minutes!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ No extension needed');
    END IF;
END;
/

-- Test 3: Check time remaining
SELECT 
    auction_id,
    ROUND(get_auction_time_remaining(auction_id)) AS seconds_remaining,
    CASE 
        WHEN get_auction_time_remaining(auction_id) <= 300 THEN 'SOFT CLOSE ZONE'
        WHEN get_auction_time_remaining(auction_id) > 300 THEN 'NORMAL'
        ELSE 'EXPIRED'
    END AS auction_status
FROM auctions
WHERE auction_id = 1;
*/

-- ============================================================================
-- Soft-Close Functions Created Successfully
-- ============================================================================
-- Functions:
--   1. check_and_extend_auction(auction_id, bid_time)
--      - Extends auction by 5 min if bid placed in last 5 min
--      - Returns: 1 if extended, 0 if not
--
--   2. get_auction_time_remaining(auction_id)
--      - Returns seconds remaining in auction
--
-- Spring Boot Usage Example:
--   StoredProcedureQuery query = em.createStoredProcedureQuery("check_and_extend_auction");
--   query.registerStoredProcedureParameter(1, Long.class, ParameterMode.IN);
--   query.registerStoredProcedureParameter(2, Timestamp.class, ParameterMode.IN);
--   query.registerStoredProcedureParameter(3, Integer.class, ParameterMode.OUT);
--   query.setParameter(1, auctionId);
--   query.setParameter(2, bidTime);
--   query.execute();
--   Integer extended = (Integer) query.getOutputParameterValue(3);
-- ============================================================================
