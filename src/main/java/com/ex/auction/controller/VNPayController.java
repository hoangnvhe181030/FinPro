package com.ex.auction.controller;

import com.ex.auction.service.VNPayService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/vnpay")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class VNPayController {

    private final VNPayService vnPayService;

    /**
     * POST /api/vnpay/create-payment
     * Create VNPay payment URL for deposit
     */
    @PostMapping("/create-payment")
    public ResponseEntity<Map<String, String>> createPayment(
            @RequestBody Map<String, Object> request,
            HttpServletRequest httpRequest) {

        long userId = ((Number) request.get("userId")).longValue();
        long amount = ((Number) request.get("amount")).longValue();

        log.info("POST /api/vnpay/create-payment - userId: {}, amount: {}", userId, amount);

        // Get client IP
        String ipAddress = httpRequest.getHeader("X-Forwarded-For");
        if (ipAddress == null || ipAddress.isEmpty()) {
            ipAddress = httpRequest.getRemoteAddr();
        }
        // Default IP for emulator
        if ("0:0:0:0:0:0:0:1".equals(ipAddress) || "127.0.0.1".equals(ipAddress)) {
            ipAddress = "13.160.92.202";
        }

        String paymentUrl = vnPayService.createPaymentUrl(userId, amount, ipAddress);

        Map<String, String> response = new HashMap<>();
        response.put("paymentUrl", paymentUrl);

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/vnpay/return
     * VNPay redirects user here after payment
     * Returns an HTML page showing payment result
     */
    @GetMapping(value = "/return", produces = MediaType.TEXT_HTML_VALUE)
    public String vnPayReturn(HttpServletRequest request) {
        log.info("GET /api/vnpay/return");

        // Collect all VNPay params
        Map<String, String> params = new HashMap<>();
        request.getParameterMap().forEach((key, values) -> {
            if (values != null && values.length > 0) {
                params.put(key, values[0]);
            }
        });

        log.info("VNPay return params: {}", params);

        // Validate checksum
        boolean isValid = vnPayService.validateChecksum(params);
        String responseCode = params.get("vnp_ResponseCode");
        boolean isSuccess = isValid && "00".equals(responseCode);

        // Process payment if valid
        if (isValid) {
            vnPayService.processPayment(params);
        }

        // Return HTML page for WebView
        String amountStr = params.get("vnp_Amount");
        long displayAmount = 0;
        if (amountStr != null) {
            displayAmount = Long.parseLong(amountStr) / 100;
        }
        String txnRef = params.getOrDefault("vnp_TxnRef", "N/A");

        return "<!DOCTYPE html>" +
                "<html><head><meta charset='UTF-8'>" +
                "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" +
                "<style>" +
                "* { margin: 0; padding: 0; box-sizing: border-box; }" +
                "body { font-family: -apple-system, sans-serif; background: #0D0F14; color: white; " +
                "display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }" +
                ".card { background: #1A1D27; border-radius: 24px; padding: 40px 32px; text-align: center; " +
                "max-width: 360px; width: 100%; }" +
                ".icon { font-size: 64px; margin-bottom: 20px; }" +
                ".title { font-size: 22px; font-weight: 700; margin-bottom: 8px; }" +
                ".amount { font-size: 28px; font-weight: 800; color: " + (isSuccess ? "#00E676" : "#FF5252") + "; " +
                "margin: 16px 0; }" +
                ".info { font-size: 13px; color: #888; margin-bottom: 6px; }" +
                ".status { display: inline-block; padding: 6px 16px; border-radius: 20px; font-size: 13px; " +
                "font-weight: 600; margin-top: 16px; background: " + (isSuccess ? "rgba(0,230,118,0.15)" : "rgba(255,82,82,0.15)") + "; " +
                "color: " + (isSuccess ? "#00E676" : "#FF5252") + "; }" +
                ".note { font-size: 12px; color: #666; margin-top: 24px; }" +
                "</style></head><body>" +
                "<div class='card'>" +
                "<div class='icon'>" + (isSuccess ? "✅" : "❌") + "</div>" +
                "<div class='title'>" + (isSuccess ? "Nạp tiền thành công!" : "Thanh toán thất bại") + "</div>" +
                "<div class='amount'>" + String.format("%,d", displayAmount) + "đ</div>" +
                "<div class='info'>Mã giao dịch: " + txnRef + "</div>" +
                "<div class='status'>" + (isSuccess ? "THÀNH CÔNG" : "THẤT BẠI") + "</div>" +
                "<div class='note'>Tự động quay lại ứng dụng...</div>" +
                "</div></body></html>";
    }

    /**
     * GET /api/vnpay/ipn
     * VNPay calls this endpoint asynchronously to notify payment result
     */
    @GetMapping("/ipn")
    public ResponseEntity<Map<String, String>> vnPayIPN(HttpServletRequest request) {
        log.info("GET /api/vnpay/ipn");

        Map<String, String> params = new HashMap<>();
        request.getParameterMap().forEach((key, values) -> {
            if (values != null && values.length > 0) {
                params.put(key, values[0]);
            }
        });

        Map<String, String> response = new HashMap<>();

        // Validate checksum
        if (!vnPayService.validateChecksum(params)) {
            response.put("RspCode", "97");
            response.put("Message", "Invalid Checksum");
            return ResponseEntity.ok(response);
        }

        // Process payment
        boolean processed = vnPayService.processPayment(params);

        if (processed) {
            response.put("RspCode", "00");
            response.put("Message", "Confirm Success");
        } else {
            response.put("RspCode", "02");
            response.put("Message", "Order already confirmed or failed");
        }

        return ResponseEntity.ok(response);
    }
}
