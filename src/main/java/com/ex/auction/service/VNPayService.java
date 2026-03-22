package com.ex.auction.service;

import com.ex.auction.config.VNPayConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class VNPayService {

    private final VNPayConfig vnPayConfig;
    private final WalletService walletService;

    // Track processed transactions to prevent duplicates
    private final Set<String> processedTxnRefs = Collections.synchronizedSet(new HashSet<>());

    /**
     * Create VNPay payment URL
     *
     * @param userId    User ID
     * @param amount    Amount in VND (e.g. 100000)
     * @param ipAddress Client IP address
     * @return VNPay payment URL
     */
    public String createPaymentUrl(long userId, long amount, String ipAddress) {
        log.info("Creating VNPay payment URL: userId={}, amount={}", userId, amount);

        String vnp_Version = "2.1.0";
        String vnp_Command = "pay";
        String vnp_TxnRef = userId + "_" + System.currentTimeMillis();
        String vnp_OrderInfo = "Deposit " + amount + " VND for user " + userId;
        String vnp_OrderType = "other";
        long vnp_Amount = amount * 100; // VNPay requires amount * 100
        String vnp_Locale = "vn";
        String vnp_IpAddr = ipAddress;

        // Create date
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
        String vnp_CreateDate = formatter.format(cal.getTime());

        // Expire date (+15 minutes)
        cal.add(Calendar.MINUTE, 15);
        String vnp_ExpireDate = formatter.format(cal.getTime());

        // Build params map (sorted by key)
        Map<String, String> vnp_Params = new TreeMap<>();
        vnp_Params.put("vnp_Version", vnp_Version);
        vnp_Params.put("vnp_Command", vnp_Command);
        vnp_Params.put("vnp_TmnCode", vnPayConfig.getTmnCode());
        vnp_Params.put("vnp_Amount", String.valueOf(vnp_Amount));
        vnp_Params.put("vnp_CurrCode", "VND");
        vnp_Params.put("vnp_TxnRef", vnp_TxnRef);
        vnp_Params.put("vnp_OrderInfo", vnp_OrderInfo);
        vnp_Params.put("vnp_OrderType", vnp_OrderType);
        vnp_Params.put("vnp_Locale", vnp_Locale);
        vnp_Params.put("vnp_ReturnUrl", vnPayConfig.getReturnUrl());
        vnp_Params.put("vnp_IpAddr", vnp_IpAddr);
        vnp_Params.put("vnp_CreateDate", vnp_CreateDate);
        vnp_Params.put("vnp_ExpireDate", vnp_ExpireDate);

        // Build hash data and query string
        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();

        Iterator<Map.Entry<String, String>> itr = vnp_Params.entrySet().iterator();
        while (itr.hasNext()) {
            Map.Entry<String, String> entry = itr.next();
            hashData.append(entry.getKey()).append('=')
                    .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
            query.append(URLEncoder.encode(entry.getKey(), StandardCharsets.US_ASCII))
                    .append('=')
                    .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
            if (itr.hasNext()) {
                hashData.append('&');
                query.append('&');
            }
        }

        // Generate secure hash
        String vnp_SecureHash = vnPayConfig.hmacSHA512(hashData.toString());
        query.append("&vnp_SecureHash=").append(vnp_SecureHash);

        String paymentUrl = vnPayConfig.getUrl() + "?" + query;
        log.info("VNPay payment URL created: txnRef={}", vnp_TxnRef);

        return paymentUrl;
    }

    /**
     * Validate VNPay return/IPN parameters
     *
     * @param params Request parameters from VNPay
     * @return true if checksum is valid
     */
    public boolean validateChecksum(Map<String, String> params) {
        String vnp_SecureHash = params.get("vnp_SecureHash");
        if (vnp_SecureHash == null) return false;

        // Remove hash params for validation
        Map<String, String> fieldsToHash = new TreeMap<>(params);
        fieldsToHash.remove("vnp_SecureHash");
        fieldsToHash.remove("vnp_SecureHashType");

        // Build hash data string
        StringBuilder hashData = new StringBuilder();
        Iterator<Map.Entry<String, String>> itr = fieldsToHash.entrySet().iterator();
        while (itr.hasNext()) {
            Map.Entry<String, String> entry = itr.next();
            if (entry.getValue() != null && !entry.getValue().isEmpty()) {
                hashData.append(entry.getKey()).append('=')
                        .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
                if (itr.hasNext()) {
                    hashData.append('&');
                }
            }
        }

        String calculatedHash = vnPayConfig.hmacSHA512(hashData.toString());

        boolean valid = calculatedHash.equalsIgnoreCase(vnp_SecureHash);
        log.info("VNPay checksum validation: {}", valid ? "PASSED" : "FAILED");
        return valid;
    }

    /**
     * Process successful VNPay payment - deposit funds to wallet
     *
     * @param params VNPay return parameters
     * @return true if payment processed successfully
     */
    public boolean processPayment(Map<String, String> params) {
        String responseCode = params.get("vnp_ResponseCode");
        String txnRef = params.get("vnp_TxnRef");
        String amountStr = params.get("vnp_Amount");

        log.info("Processing VNPay payment: txnRef={}, responseCode={}", txnRef, responseCode);

        // Check response code (00 = success)
        if (!"00".equals(responseCode)) {
            log.warn("VNPay payment failed: responseCode={}", responseCode);
            return false;
        }

        // Prevent duplicate processing
        if (processedTxnRefs.contains(txnRef)) {
            log.warn("Transaction already processed: {}", txnRef);
            return true; // Already processed, still return success
        }

        try {
            // Extract userId from txnRef (format: userId_timestamp)
            String[] parts = txnRef.split("_");
            long userId = Long.parseLong(parts[0]);

            // VNPay amount is multiplied by 100
            long amount = Long.parseLong(amountStr) / 100;

            // Deposit to wallet
            walletService.deposit(userId, java.math.BigDecimal.valueOf(amount));

            // Mark as processed
            processedTxnRefs.add(txnRef);

            log.info("VNPay payment processed successfully: userId={}, amount={}", userId, amount);
            return true;
        } catch (Exception e) {
            log.error("Failed to process VNPay payment: {}", e.getMessage(), e);
            return false;
        }
    }
}
