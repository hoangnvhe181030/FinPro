    -- ============================================================================
    -- OracleSQL Auction System - Index Creation Script
    -- ============================================================================
    -- Description: Creates optimized indexes for read-heavy workload
    -- Strategy: Prioritize frequent queries (active auctions, bid history, wallet lookup)
    -- Date: 2026-01-20
    -- ============================================================================

    -- ============================================================================
    -- USERS TABLE INDEXES
    -- ============================================================================
    CREATE INDEX idx_users_email ON users(email);
    CREATE INDEX idx_users_status ON users(status);

    COMMENT ON INDEX idx_users_email IS 'Fast email lookup for login';
    COMMENT ON INDEX idx_users_status IS 'Filter active/banned users';

    -- ============================================================================
    -- WALLETS TABLE INDEXES
    -- ============================================================================
    CREATE INDEX idx_wallets_user_id ON wallets(user_id);

    COMMENT ON INDEX idx_wallets_user_id IS 'Fast user wallet lookup (most frequent query)';

    -- ============================================================================
    -- CATEGORIES TABLE INDEXES
    -- ============================================================================
    CREATE INDEX idx_categories_parent ON categories(parent_category_id);

    COMMENT ON INDEX idx_categories_parent IS 'Hierarchical category traversal';

    -- ============================================================================
    -- PRODUCTS TABLE INDEXES
    -- ============================================================================
    CREATE INDEX idx_products_category ON products(category_id);
    CREATE INDEX idx_products_name ON products(product_name);

    COMMENT ON INDEX idx_products_category IS 'Browse products by category';
    COMMENT ON INDEX idx_products_name IS 'Product search by name';

    -- ============================================================================
    -- AUCTIONS TABLE INDEXES (Most Critical for Read Performance)
    -- ============================================================================
    -- Primary index for homepage "Active Auctions" query
    CREATE INDEX idx_auctions_status ON auctions(status);

    -- Composite index for filtering active auctions by end time
    CREATE INDEX idx_auctions_status_end ON auctions(status, end_time);

    -- Fast lookup by seller (My Auctions page)
    CREATE INDEX idx_auctions_seller ON auctions(seller_id);

    -- Fast lookup by product
    CREATE INDEX idx_auctions_product ON auctions(product_id);

    -- Index for auction expiration job (find auctions to close)
    CREATE INDEX idx_auctions_end_time ON auctions(end_time);

    COMMENT ON INDEX idx_auctions_status IS 'Filter by auction status';
    COMMENT ON INDEX idx_auctions_status_end IS 'CRITICAL: Homepage active auctions query';
    COMMENT ON INDEX idx_auctions_seller IS 'Seller dashboard - my auctions';
    COMMENT ON INDEX idx_auctions_end_time IS 'Auction expiration job';

    -- ============================================================================
    -- BIDS TABLE INDEXES (High Read Traffic)
    -- ============================================================================
    -- Bid history for auction detail page (ordered by time DESC)
    CREATE INDEX idx_bids_auction_time ON bids(auction_id, bid_time DESC);

    -- Leaderboard query (highest bids first)
    CREATE INDEX idx_bids_auction_amount ON bids(auction_id, bid_amount DESC, bid_time);

    -- User's bid history
    CREATE INDEX idx_bids_user ON bids(user_id, bid_time DESC);

    -- Filter by bid status
    CREATE INDEX idx_bids_status ON bids(bid_status);

    COMMENT ON INDEX idx_bids_auction_time IS 'Auction detail page - bid history timeline';
    COMMENT ON INDEX idx_bids_auction_amount IS 'CRITICAL: Bid leaderboard (highest bidder)';
    COMMENT ON INDEX idx_bids_user IS 'User dashboard - my bids';

    -- ============================================================================
    -- WALLET_TRANSACTIONS TABLE INDEXES
    -- ============================================================================
    -- User transaction history
    CREATE INDEX idx_wt_wallet ON wallet_transactions(wallet_id, created_at DESC);
    CREATE INDEX idx_wt_user ON wallet_transactions(user_id, created_at DESC);

    -- Audit trail by auction
    CREATE INDEX idx_wt_auction ON wallet_transactions(auction_id);

    -- Filter by transaction type
    CREATE INDEX idx_wt_type ON wallet_transactions(transaction_type);

    COMMENT ON INDEX idx_wt_wallet IS 'Wallet transaction history';
    COMMENT ON INDEX idx_wt_user IS 'User transaction history';
    COMMENT ON INDEX idx_wt_auction IS 'Audit trail for specific auction';

    -- ============================================================================
    -- AUCTION_EVENTS TABLE INDEXES
    -- ============================================================================
    CREATE INDEX idx_ae_auction ON auction_events(auction_id, event_time);
    CREATE INDEX idx_ae_processed ON auction_events(processed, event_time);

    COMMENT ON INDEX idx_ae_auction IS 'Event timeline for auction';
    COMMENT ON INDEX idx_ae_processed IS 'Kafka publisher polling unprocessed events';

    -- ============================================================================
    -- BID_EVENTS TABLE INDEXES
    -- ============================================================================
    CREATE INDEX idx_be_bid ON bid_events(bid_id, event_time);
    CREATE INDEX idx_be_processed ON bid_events(processed, event_time);

    COMMENT ON INDEX idx_be_bid IS 'Event timeline for bid';
    COMMENT ON INDEX idx_be_processed IS 'Kafka consumer polling';

    -- ============================================================================
    -- OUTBOX TABLE INDEXES (Critical for Kafka Publishing)
    -- ============================================================================
    CREATE INDEX idx_outbox_published ON outbox(published, created_at);

    COMMENT ON INDEX idx_outbox_published IS 'CRITICAL: Outbox publisher polling (WHERE published = N)';

    -- ============================================================================
    -- All indexes created successfully
    -- Read-optimized indexes for: Active auctions, Bid leaderboard, Wallet lookup
    -- ============================================================================
