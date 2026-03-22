package com.ex.auction.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
@Slf4j
public class AdminReportService {

    private final EntityManager entityManager;

    // Entity configurations: entity name -> table info
    private static final Map<String, EntityConfig> ENTITY_CONFIGS = new LinkedHashMap<>();

    static {
        ENTITY_CONFIGS.put("users", new EntityConfig("users", "user_id", List.of(
                new FieldConfig("user_id", "ID", "number"),
                new FieldConfig("username", "Username", "text"),
                new FieldConfig("email", "Email", "text"),
                new FieldConfig("full_name", "Full Name", "text"),
                new FieldConfig("phone_number", "Phone", "text"),
                new FieldConfig("status", "Status", "enum", List.of("ACTIVE", "INACTIVE", "BANNED")),
                new FieldConfig("created_at", "Created At", "date"),
                new FieldConfig("updated_at", "Updated At", "date")
        )));

        ENTITY_CONFIGS.put("auctions", new EntityConfig("auctions", "auction_id", List.of(
                new FieldConfig("auction_id", "ID", "number"),
                new FieldConfig("product_id", "Product ID", "number"),
                new FieldConfig("seller_id", "Seller ID", "number"),
                new FieldConfig("winner_id", "Winner ID", "number"),
                new FieldConfig("starting_price", "Starting Price", "number"),
                new FieldConfig("current_price", "Current Price", "number"),
                new FieldConfig("reserve_price", "Reserve Price", "number"),
                new FieldConfig("bid_increment", "Bid Increment", "number"),
                new FieldConfig("start_time", "Start Time", "date"),
                new FieldConfig("end_time", "End Time", "date"),
                new FieldConfig("status", "Status", "enum", List.of("PENDING", "ACTIVE", "ENDED", "CANCELLED", "SETTLED")),
                new FieldConfig("total_bids", "Total Bids", "number"),
                new FieldConfig("created_at", "Created At", "date")
        )));

        ENTITY_CONFIGS.put("products", new EntityConfig("products", "product_id", List.of(
                new FieldConfig("product_id", "ID", "number"),
                new FieldConfig("category_id", "Category ID", "number"),
                new FieldConfig("product_name", "Product Name", "text"),
                new FieldConfig("description", "Description", "text"),
                new FieldConfig("condition", "Condition", "enum", List.of("NEW", "LIKE_NEW", "GOOD", "FAIR", "POOR")),
                new FieldConfig("created_at", "Created At", "date")
        )));

        ENTITY_CONFIGS.put("bids", new EntityConfig("bids", "bid_id", List.of(
                new FieldConfig("bid_id", "ID", "number"),
                new FieldConfig("auction_id", "Auction ID", "number"),
                new FieldConfig("user_id", "User ID", "number"),
                new FieldConfig("bid_amount", "Bid Amount", "number"),
                new FieldConfig("bid_status", "Status", "enum", List.of("PENDING", "ACCEPTED", "REJECTED", "OUTBID")),
                new FieldConfig("bid_time", "Bid Time", "date")
        )));

        ENTITY_CONFIGS.put("wallets", new EntityConfig("wallets", "wallet_id", List.of(
                new FieldConfig("wallet_id", "ID", "number"),
                new FieldConfig("user_id", "User ID", "number"),
                new FieldConfig("balance", "Balance", "number"),
                new FieldConfig("reserved_balance", "Reserved", "number"),
                new FieldConfig("currency", "Currency", "text"),
                new FieldConfig("created_at", "Created At", "date")
        )));

        ENTITY_CONFIGS.put("wallet_transactions", new EntityConfig("wallet_transactions", "transaction_id", List.of(
                new FieldConfig("transaction_id", "ID", "number"),
                new FieldConfig("wallet_id", "Wallet ID", "number"),
                new FieldConfig("user_id", "User ID", "number"),
                new FieldConfig("auction_id", "Auction ID", "number"),
                new FieldConfig("transaction_type", "Type", "enum",
                        List.of("DEPOSIT", "WITHDRAW", "BID_RESERVE", "BID_RELEASE", "PAYMENT", "REFUND", "PAYOUT")),
                new FieldConfig("amount", "Amount", "number"),
                new FieldConfig("balance_before", "Balance Before", "number"),
                new FieldConfig("balance_after", "Balance After", "number"),
                new FieldConfig("status", "Status", "enum", List.of("PENDING", "COMPLETED", "FAILED", "REVERSED")),
                new FieldConfig("description", "Description", "text"),
                new FieldConfig("created_at", "Created At", "date")
        )));

        ENTITY_CONFIGS.put("chat_messages", new EntityConfig("chat_messages", "message_id", List.of(
                new FieldConfig("message_id", "ID", "number"),
                new FieldConfig("sender_id", "Sender ID", "number"),
                new FieldConfig("receiver_id", "Receiver ID", "number"),
                new FieldConfig("content", "Content", "text"),
                new FieldConfig("is_read", "Read", "enum", List.of("Y", "N")),
                new FieldConfig("created_at", "Created At", "date")
        )));
    }

    /**
     * Get available entities and their fields (metadata)
     */
    public Map<String, Object> getMetadata() {
        Map<String, Object> result = new LinkedHashMap<>();
        ENTITY_CONFIGS.forEach((name, config) -> {
            Map<String, Object> entityInfo = new LinkedHashMap<>();
            entityInfo.put("table", config.table);
            entityInfo.put("primaryKey", config.primaryKey);
            entityInfo.put("fields", config.fields.stream().map(f -> {
                Map<String, Object> fieldInfo = new LinkedHashMap<>();
                fieldInfo.put("column", f.column);
                fieldInfo.put("label", f.label);
                fieldInfo.put("type", f.type);
                if (f.enumValues != null) fieldInfo.put("enumValues", f.enumValues);
                return fieldInfo;
            }).collect(Collectors.toList()));
            result.put(name, entityInfo);
        });
        return result;
    }

    /**
     * Execute dynamic report query
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> executeReport(String entity, List<String> fields,
                                              Map<String, String> filters,
                                              String sortBy, String sortDir,
                                              int page, int size) {
        EntityConfig config = ENTITY_CONFIGS.get(entity);
        if (config == null) throw new IllegalArgumentException("Unknown entity: " + entity);

        // Validate fields
        Set<String> validColumns = config.fields.stream().map(f -> f.column).collect(Collectors.toSet());
        List<String> selectFields = (fields == null || fields.isEmpty())
                ? config.fields.stream().map(f -> f.column).collect(Collectors.toList())
                : fields.stream().filter(validColumns::contains).collect(Collectors.toList());

        if (selectFields.isEmpty()) {
            selectFields = config.fields.stream().map(f -> f.column).collect(Collectors.toList());
        }

        // Build WHERE clause
        StringBuilder where = new StringBuilder();
        List<Object> params = new ArrayList<>();
        int paramIndex = 1;

        if (filters != null) {
            for (Map.Entry<String, String> entry : filters.entrySet()) {
                String col = entry.getKey();
                String val = entry.getValue();
                if (!validColumns.contains(col) || val == null || val.isEmpty()) continue;

                FieldConfig fieldConfig = config.fields.stream()
                        .filter(f -> f.column.equals(col)).findFirst().orElse(null);
                if (fieldConfig == null) continue;

                if (!where.isEmpty()) where.append(" AND ");

                switch (fieldConfig.type) {
                    case "text":
                        where.append("LOWER(").append(col).append(") LIKE ?").append(paramIndex++);
                        params.add("%" + val.toLowerCase() + "%");
                        break;
                    case "enum":
                        where.append(col).append(" = ?").append(paramIndex++);
                        params.add(val);
                        break;
                    case "number":
                        where.append(col).append(" = ?").append(paramIndex++);
                        params.add(Double.parseDouble(val));
                        break;
                    case "date":
                        // Support date range: "2026-01-01,2026-12-31"
                        if (val.contains(",")) {
                            String[] range = val.split(",");
                            where.append(col).append(" >= TO_TIMESTAMP(?").append(paramIndex++).append(", 'YYYY-MM-DD')");
                            params.add(range[0].trim());
                            where.append(" AND ").append(col).append(" <= TO_TIMESTAMP(?").append(paramIndex++).append(", 'YYYY-MM-DD') + 1");
                            params.add(range[1].trim());
                        }
                        break;
                }
            }
        }

        String selectClause = String.join(", ", selectFields);
        String baseQuery = "SELECT " + selectClause + " FROM " + config.table;
        String countQuery = "SELECT COUNT(*) FROM " + config.table;

        if (!where.isEmpty()) {
            baseQuery += " WHERE " + where;
            countQuery += " WHERE " + where;
        }

        // Sort
        if (sortBy != null && validColumns.contains(sortBy)) {
            String dir = "DESC".equalsIgnoreCase(sortDir) ? "DESC" : "ASC";
            baseQuery += " ORDER BY " + sortBy + " " + dir;
        } else {
            baseQuery += " ORDER BY " + config.primaryKey + " DESC";
        }

        // Count total
        Query countQ = entityManager.createNativeQuery(countQuery);
        for (int i = 0; i < params.size(); i++) {
            countQ.setParameter(i + 1, params.get(i));
        }
        long total = ((Number) countQ.getSingleResult()).longValue();

        // Paginate
        Query dataQ = entityManager.createNativeQuery(baseQuery);
        for (int i = 0; i < params.size(); i++) {
            dataQ.setParameter(i + 1, params.get(i));
        }
        dataQ.setFirstResult(page * size);
        dataQ.setMaxResults(size);

        List<Object[]> rows = dataQ.getResultList();
        List<Map<String, Object>> data = new ArrayList<>();
        for (Object row : rows) {
            Map<String, Object> map = new LinkedHashMap<>();
            if (row instanceof Object[]) {
                Object[] cols = (Object[]) row;
                for (int i = 0; i < selectFields.size() && i < cols.length; i++) {
                    map.put(selectFields.get(i), cols[i] != null ? cols[i].toString() : null);
                }
            } else {
                map.put(selectFields.get(0), row != null ? row.toString() : null);
            }
            data.add(map);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("entity", entity);
        result.put("fields", selectFields);
        result.put("data", data);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        result.put("totalPages", (int) Math.ceil((double) total / size));
        return result;
    }

    /**
     * Get dashboard overview stats
     */
    public Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new LinkedHashMap<>();

        stats.put("totalUsers", countQuery("SELECT COUNT(*) FROM users"));
        stats.put("activeUsers", countQuery("SELECT COUNT(*) FROM users WHERE status = 'ACTIVE'"));
        stats.put("totalAuctions", countQuery("SELECT COUNT(*) FROM auctions"));
        stats.put("activeAuctions", countQuery("SELECT COUNT(*) FROM auctions WHERE status = 'ACTIVE'"));
        stats.put("totalProducts", countQuery("SELECT COUNT(*) FROM products"));
        stats.put("totalBids", countQuery("SELECT COUNT(*) FROM bids"));
        stats.put("totalDeposits", sumQuery("SELECT COALESCE(SUM(amount), 0) FROM wallet_transactions WHERE transaction_type = 'DEPOSIT' AND status = 'COMPLETED'"));
        stats.put("totalRevenue", sumQuery("SELECT COALESCE(SUM(amount), 0) FROM wallet_transactions WHERE transaction_type = 'PAYMENT' AND status = 'COMPLETED'"));
        stats.put("totalMessages", countQuery("SELECT COUNT(*) FROM chat_messages"));

        // Auction status distribution
        @SuppressWarnings("unchecked")
        List<Object[]> auctionDist = entityManager.createNativeQuery(
                "SELECT status, COUNT(*) FROM auctions GROUP BY status ORDER BY COUNT(*) DESC"
        ).getResultList();
        stats.put("auctionsByStatus", auctionDist.stream().map(r -> Map.of("status", r[0].toString(), "count", ((Number) r[1]).longValue())).collect(Collectors.toList()));

        // Recent transactions
        @SuppressWarnings("unchecked")
        List<Object[]> recentTx = entityManager.createNativeQuery(
                "SELECT transaction_type, COUNT(*), COALESCE(SUM(amount), 0) FROM wallet_transactions WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '7' DAY GROUP BY transaction_type"
        ).getResultList();
        stats.put("recentTransactions", recentTx.stream().map(r -> Map.of(
                "type", r[0].toString(),
                "count", ((Number) r[1]).longValue(),
                "total", ((Number) r[2]).doubleValue()
        )).collect(Collectors.toList()));

        return stats;
    }

    // ---- Top Rankings (Aggregate Queries) ----

    private static final Map<String, RankingConfig> RANKING_CONFIGS = new LinkedHashMap<>();

    static {
        RANKING_CONFIGS.put("top_winners", new RankingConfig(
                "Top Users by Wins",
                "SELECT u.user_id, u.username, u.full_name, COUNT(*) as wins " +
                "FROM auctions a JOIN users u ON a.winner_id = u.user_id " +
                "WHERE a.status IN ('ENDED', 'SETTLED') AND a.winner_id IS NOT NULL " +
                "GROUP BY u.user_id, u.username, u.full_name ORDER BY wins DESC",
                List.of("user_id", "username", "full_name", "wins"),
                List.of("ID", "Username", "Full Name", "Wins"),
                "bar"
        ));

        RANKING_CONFIGS.put("top_bidders", new RankingConfig(
                "Top Users by Total Bids",
                "SELECT u.user_id, u.username, u.full_name, COUNT(*) as total_bids, " +
                "COALESCE(SUM(b.bid_amount), 0) as total_amount " +
                "FROM bids b JOIN users u ON b.user_id = u.user_id " +
                "GROUP BY u.user_id, u.username, u.full_name ORDER BY total_bids DESC",
                List.of("user_id", "username", "full_name", "total_bids", "total_amount"),
                List.of("ID", "Username", "Full Name", "Total Bids", "Total Amount"),
                "bar"
        ));

        RANKING_CONFIGS.put("top_products_price", new RankingConfig(
                "Top Products by Highest Bid Price",
                "SELECT p.product_id, p.product_name, p.condition, a.current_price, a.total_bids, a.status " +
                "FROM auctions a JOIN products p ON a.product_id = p.product_id " +
                "ORDER BY a.current_price DESC",
                List.of("product_id", "product_name", "condition", "current_price", "total_bids", "status"),
                List.of("ID", "Product Name", "Condition", "Current Price", "Total Bids", "Status"),
                "bar"
        ));

        RANKING_CONFIGS.put("top_sellers", new RankingConfig(
                "Top Sellers by Revenue",
                "SELECT u.user_id, u.username, u.full_name, COUNT(*) as auctions_sold, " +
                "COALESCE(SUM(a.current_price), 0) as total_revenue " +
                "FROM auctions a JOIN users u ON a.seller_id = u.user_id " +
                "WHERE a.status IN ('ENDED', 'SETTLED') " +
                "GROUP BY u.user_id, u.username, u.full_name ORDER BY total_revenue DESC",
                List.of("user_id", "username", "full_name", "auctions_sold", "total_revenue"),
                List.of("ID", "Username", "Full Name", "Auctions Sold", "Total Revenue"),
                "bar"
        ));

        RANKING_CONFIGS.put("top_depositors", new RankingConfig(
                "Top Users by Deposit Amount",
                "SELECT u.user_id, u.username, u.full_name, COUNT(*) as deposits, " +
                "COALESCE(SUM(wt.amount), 0) as total_deposited " +
                "FROM wallet_transactions wt JOIN users u ON wt.user_id = u.user_id " +
                "WHERE wt.transaction_type = 'DEPOSIT' AND wt.status = 'COMPLETED' " +
                "GROUP BY u.user_id, u.username, u.full_name ORDER BY total_deposited DESC",
                List.of("user_id", "username", "full_name", "deposits", "total_deposited"),
                List.of("ID", "Username", "Full Name", "Deposits", "Total Deposited"),
                "bar"
        ));

        RANKING_CONFIGS.put("top_chatters", new RankingConfig(
                "Most Active Chat Users",
                "SELECT u.user_id, u.username, u.full_name, COUNT(*) as messages_sent " +
                "FROM chat_messages cm JOIN users u ON cm.sender_id = u.user_id " +
                "GROUP BY u.user_id, u.username, u.full_name ORDER BY messages_sent DESC",
                List.of("user_id", "username", "full_name", "messages_sent"),
                List.of("ID", "Username", "Full Name", "Messages Sent"),
                "bar"
        ));

        RANKING_CONFIGS.put("auction_by_category", new RankingConfig(
                "Auctions by Category",
                "SELECT c.category_name, COUNT(*) as auction_count, " +
                "COALESCE(SUM(a.current_price), 0) as total_value " +
                "FROM auctions a JOIN products p ON a.product_id = p.product_id " +
                "JOIN categories c ON p.category_id = c.category_id " +
                "GROUP BY c.category_name ORDER BY auction_count DESC",
                List.of("category_name", "auction_count", "total_value"),
                List.of("Category", "Auction Count", "Total Value"),
                "pie"
        ));

        RANKING_CONFIGS.put("wallet_balances", new RankingConfig(
                "Top Users by Wallet Balance",
                "SELECT u.user_id, u.username, u.full_name, w.balance, w.reserved_balance " +
                "FROM wallets w JOIN users u ON w.user_id = u.user_id " +
                "ORDER BY w.balance DESC",
                List.of("user_id", "username", "full_name", "balance", "reserved_balance"),
                List.of("ID", "Username", "Full Name", "Balance", "Reserved"),
                "bar"
        ));
    }

    /**
     * Get available ranking reports
     */
    public List<Map<String, Object>> getRankingList() {
        return RANKING_CONFIGS.entrySet().stream().map(e -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("key", e.getKey());
            map.put("title", e.getValue().title);
            map.put("chartType", e.getValue().chartType);
            return map;
        }).collect(Collectors.toList());
    }

    /**
     * Execute a ranking report
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> executeRanking(String key, int limit) {
        RankingConfig config = RANKING_CONFIGS.get(key);
        if (config == null) throw new IllegalArgumentException("Unknown ranking: " + key);

        String sql = config.sql;
        // Add FETCH FIRST for Oracle
        sql += " FETCH FIRST " + limit + " ROWS ONLY";

        List<Object[]> rows = entityManager.createNativeQuery(sql).getResultList();
        List<Map<String, Object>> data = new ArrayList<>();

        for (Object row : rows) {
            Map<String, Object> map = new LinkedHashMap<>();
            if (row instanceof Object[]) {
                Object[] cols = (Object[]) row;
                for (int i = 0; i < config.columns.size() && i < cols.length; i++) {
                    map.put(config.columns.get(i), cols[i] != null ? cols[i].toString() : null);
                }
            } else {
                map.put(config.columns.get(0), row != null ? row.toString() : null);
            }
            data.add(map);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("key", key);
        result.put("title", config.title);
        result.put("columns", config.columns);
        result.put("labels", config.labels);
        result.put("chartType", config.chartType);
        result.put("data", data);
        return result;
    }

    private long countQuery(String sql) {
        try {
            return ((Number) entityManager.createNativeQuery(sql).getSingleResult()).longValue();
        } catch (Exception e) {
            return 0;
        }
    }

    private double sumQuery(String sql) {
        try {
            return ((Number) entityManager.createNativeQuery(sql).getSingleResult()).doubleValue();
        } catch (Exception e) {
            return 0;
        }
    }

    // Inner config classes
    record EntityConfig(String table, String primaryKey, List<FieldConfig> fields) {}

    record FieldConfig(String column, String label, String type, List<String> enumValues) {
        FieldConfig(String column, String label, String type) {
            this(column, label, type, null);
        }
    }

    record RankingConfig(String title, String sql, List<String> columns, List<String> labels, String chartType) {}
}
