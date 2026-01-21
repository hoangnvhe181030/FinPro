# OracleSQL Auction System - Database Scripts

> **Complete database setup for English Auction system with Kafka integration**

---

## 📁 Files Overview

| File | Purpose | When to Run |
|------|---------|-------------|
| `01_create_tables.sql` | Create all 10 tables with constraints | First deployment |
| `02_create_indexes.sql` | Create optimized indexes for read-heavy workload | After tables |
| `03_create_triggers.sql` | Auto-update triggers for timestamps and versions | After tables |
| `04_soft_close_function.sql` | PL/SQL function for soft-close mechanism | After tables |
| `05_sample_data.sql` | Insert test data (DEV only) | Optional - testing only |

---

## 🚀 Deployment Order

### **Step 1: Create Database Objects**

Run scripts in this **exact order**:

```bash
sqlplus username/password@database

@01_create_tables.sql
@02_create_indexes.sql
@03_create_triggers.sql
@04_soft_close_function.sql
```

### **Step 2: Verify Deployment**

```sql
-- Check all tables exist
SELECT table_name FROM user_tables 
WHERE table_name IN ('USERS', 'WALLETS', 'AUCTIONS', 'BIDS', 'PRODUCTS', 
                     'CATEGORIES', 'WALLET_TRANSACTIONS', 'AUCTION_EVENTS', 
                     'BID_EVENTS', 'OUTBOX')
ORDER BY table_name;

-- Check indexes
SELECT index_name, table_name FROM user_indexes
WHERE table_name IN ('AUCTIONS', 'BIDS', 'WALLETS')
ORDER BY table_name, index_name;

-- Check functions
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_type = 'FUNCTION' 
AND object_name IN ('CHECK_AND_EXTEND_AUCTION', 'GET_AUCTION_TIME_REMAINING');
```

### **Step 3 (Optional): Load Test Data**

⚠️ **Only in DEV/TEST environments!**

```bash
@05_sample_data.sql
```

---

## 📊 Database Schema

### **Core Tables (10 Total)**

1. **users** - User accounts
2. **wallets** - User balances with optimistic locking
3. **categories** - Hierarchical product categories
4. **products** - Auction items
5. **auctions** - Core auction management with soft-close
6. **bids** - Immutable bid history (event sourcing)
7. **wallet_transactions** - Financial audit trail
8. **auction_events** - Auction state changes
9. **bid_events** - Bid processing events
10. **outbox** - Transactional outbox for Kafka

### **Relationships**

```
users 1--* wallets
users 1--* auctions (as seller)
users 1--* bids
categories 1--* products
products 1--* auctions
auctions 1--* bids
auctions 1--* auction_events
bids 1--1 bid_events
```

---

## 🔧 Key Features

### **1. Race Condition Handling**

- **Strategy**: Kafka message queue + Event Sourcing
- **Tables**: `bids` (immutable), `bid_events`, `outbox`
- **Spring Boot Integration**: Handle wallet reserve/release in Java

### **2. Soft-Close Mechanism**

- **Function**: `check_and_extend_auction(auction_id, bid_time)`
- **Rule**: Bid in last 5 minutes → extend by 5 minutes
- **Returns**: 1 if extended, 0 if not

**Spring Boot Usage:**

```java
@Repository
public class AuctionRepository {
    
    @PersistenceContext
    private EntityManager em;
    
    public boolean checkAndExtendAuction(Long auctionId, Timestamp bidTime) {
        StoredProcedureQuery query = em.createStoredProcedureQuery("check_and_extend_auction");
        query.registerStoredProcedureParameter(1, Long.class, ParameterMode.IN);
        query.registerStoredProcedureParameter(2, Timestamp.class, ParameterMode.IN);
        query.registerStoredProcedureParameter(3, Integer.class, ParameterMode.OUT);
        
        query.setParameter(1, auctionId);
        query.setParameter(2, bidTime);
        query.execute();
        
        Integer extended = (Integer) query.getOutputParameterValue(3);
        return extended == 1;
    }
}
```

### **3. Optimistic Locking**

- **Tables**: `wallets.version`, `auctions.version`
- **Purpose**: Prevent concurrent updates
- **Auto-increment**: Triggers handle version bumps

**JPA Entity Example:**

```java
@Entity
@Table(name = "wallets")
public class Wallet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long walletId;
    
    @Column(nullable = false)
    private BigDecimal balance;
    
    @Column(nullable = false)
    private BigDecimal reservedBalance;
    
    @Version
    @Column(nullable = false)
    private Long version;
    
    // getters/setters
}
```

### **4. Read-Heavy Optimization**

**Critical Indexes:**

```sql
-- Homepage: Active auctions
idx_auctions_status_end (status, end_time)

-- Auction detail: Bid leaderboard
idx_bids_auction_amount (auction_id, bid_amount DESC, bid_time)

-- User wallet lookup
idx_wallets_user_id (user_id)
```

**Performance Target**: <100ms for all queries

---

## 🧪 Testing Soft-Close

### **Scenario: Bid in Last 5 Minutes**

```sql
-- 1. Create auction ending in 3 minutes
INSERT INTO auctions (..., end_time, original_end_time, status)
VALUES (..., CURRENT_TIMESTAMP + INTERVAL '3' MINUTE, 
            CURRENT_TIMESTAMP + INTERVAL '3' MINUTE, 'ACTIVE');

-- 2. Place bid (should trigger extension)
DECLARE
    v_extended NUMBER;
BEGIN
    v_extended := check_and_extend_auction(
        p_auction_id => 1,
        p_bid_time => CURRENT_TIMESTAMP
    );
    
    IF v_extended = 1 THEN
        DBMS_OUTPUT.PUT_LINE('✅ Extended by 5 minutes!');
    END IF;
END;
/

-- 3. Verify extension
SELECT 
    auction_id,
    original_end_time,
    end_time,
    EXTRACT(MINUTE FROM (end_time - original_end_time)) AS extended_minutes
FROM auctions
WHERE auction_id = 1;
```

---

## 📈 Performance Monitoring

### **Query Performance Check**

```sql
-- Enable timing
SET TIMING ON;

-- Test critical queries
SELECT * FROM auctions 
WHERE status = 'ACTIVE' 
ORDER BY end_time;

SELECT * FROM bids 
WHERE auction_id = 1 
ORDER BY bid_amount DESC;
```

### **Index Usage Check**

```sql
EXPLAIN PLAN FOR
SELECT * FROM auctions WHERE status = 'ACTIVE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

---

## 🔒 Security Notes

1. **Never expose wallet_transactions table** - Contains sensitive financial data
2. **Hash all passwords** - Use BCrypt (shown in sample data)
3. **Audit trail** - All bids and transactions are immutable
4. **Version control** - Optimistic locking prevents race conditions

---

## 🐛 Troubleshooting

### **Issue: "ORA-00001: unique constraint violated"**

**Cause**: Duplicate username/email  
**Fix**: Check `users.username` and `users.email` are unique

### **Issue: "ORA-02292: integrity constraint violated - child record found"**

**Cause**: Trying to delete auction with bids  
**Fix**: Cascade deletes are configured - check FK constraints

### **Issue: "Function not found"**

**Cause**: Schema mismatch  
**Fix**: Ensure you're connected to correct schema

```sql
SELECT USER FROM DUAL; -- Check current schema
```

---

## 📚 Additional Resources

- [Oracle JSON Functions](https://docs.oracle.com/en/database/oracle/oracle-database/19/adjsn/json-in-oracle-database.html)
- [Optimistic Locking in JPA](https://www.baeldung.com/jpa-optimistic-locking)
- [Transactional Outbox Pattern](https://microservices.io/patterns/data/transactional-outbox.html)

---

## ✅ Deployment Checklist

- [ ] Run all 4 SQL scripts in order
- [ ] Verify all 10 tables exist
- [ ] Verify indexes created (minimum 15 indexes)
- [ ] Test soft-close function
- [ ] Load sample data (dev only)
- [ ] Configure Spring Boot JPA entities
- [ ] Set up Kafka topics (`auction.bids`, `auction.events`)
- [ ] Deploy outbox publisher service
- [ ] Load test with 1000 concurrent users

---

**Questions?** Review the main design document: `auction-schema-design.md`
