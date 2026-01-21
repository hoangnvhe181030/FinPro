package com.ex.auction.controller;

import com.ex.auction.domain.entity.Wallet;
import com.ex.auction.dto.DepositRequest;
import com.ex.auction.dto.WalletResponse;
import com.ex.auction.service.WalletService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/wallets")
@RequiredArgsConstructor
@Slf4j
public class WalletController {

    private final WalletService walletService;

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
}
