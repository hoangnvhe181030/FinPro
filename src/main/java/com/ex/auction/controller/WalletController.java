package com.ex.auction.controller;

import com.ex.auction.domain.entity.Wallet;
import com.ex.auction.domain.entity.WalletTransaction;
import com.ex.auction.dto.DepositRequest;
import com.ex.auction.dto.WalletResponse;
import com.ex.auction.repository.WalletTransactionRepository;
import com.ex.auction.service.WalletService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/wallets")
@RequiredArgsConstructor
@Slf4j
public class WalletController {

    private final WalletService walletService;
    private final WalletTransactionRepository walletTransactionRepository;

    /**
     * POST /api/wallets/deposit - Deposit funds to wallet
     */
    @PostMapping("/deposit")
    public ResponseEntity<WalletResponse> deposit(@Valid @RequestBody DepositRequest request) {
        log.info("POST /api/wallets/deposit - userId: {}, amount: {}",
                request.getUserId(), request.getAmount());

        Wallet wallet = walletService.deposit(request.getUserId(), request.getAmount());

        WalletResponse response = WalletResponse.builder()
                .userId(wallet.getUser().getUserId())
                .walletId(wallet.getWalletId())
                .balance(wallet.getBalance())
                .reservedBalance(wallet.getReservedBalance())
                .availableBalance(wallet.getBalance().subtract(wallet.getReservedBalance()))
                .currency(wallet.getCurrency())
                .build();

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/wallets/{userId} - Get wallet balance
     */
    @GetMapping("/{userId}")
    public ResponseEntity<WalletResponse> getWallet(@PathVariable Long userId) {
        log.info("GET /api/wallets/{}", userId);

        Wallet wallet = walletService.getWalletByUserId(userId);

        WalletResponse response = WalletResponse.builder()
                .userId(wallet.getUser().getUserId())
                .walletId(wallet.getWalletId())
                .balance(wallet.getBalance())
                .reservedBalance(wallet.getReservedBalance())
                .availableBalance(wallet.getBalance().subtract(wallet.getReservedBalance()))
                .currency(wallet.getCurrency())
                .build();

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/wallets/{userId}/transactions - Get transaction history
     */
    @GetMapping("/{userId}/transactions")
    public ResponseEntity<List<Map<String, Object>>> getTransactions(@PathVariable Long userId) {
        log.info("GET /api/wallets/{}/transactions", userId);

        List<WalletTransaction> transactions = walletTransactionRepository.findByUserIdOrderByCreatedAtDesc(userId);

        List<Map<String, Object>> response = transactions.stream()
                .map(tx -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("transactionId", tx.getTransactionId());
                    map.put("type", tx.getTransactionType().name());
                    map.put("amount", tx.getAmount());
                    map.put("balanceBefore", tx.getBalanceBefore());
                    map.put("balanceAfter", tx.getBalanceAfter());
                    map.put("status", tx.getStatus().name());
                    map.put("description", tx.getDescription());
                    map.put("createdAt", tx.getCreatedAt().toString());
                    return map;
                })
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }
}

