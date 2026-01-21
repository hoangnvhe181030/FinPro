package com.ex.auction.service;

import com.ex.auction.domain.entity.User;
import com.ex.auction.domain.entity.Wallet;
import com.ex.auction.domain.entity.WalletTransaction;
import com.ex.auction.domain.enums.TransactionStatus;
import com.ex.auction.domain.enums.TransactionType;
import com.ex.auction.exception.InsufficientFundsException;
import com.ex.auction.exception.WalletNotFoundException;
import com.ex.auction.repository.UserRepository;
import com.ex.auction.repository.WalletRepository;
import com.ex.auction.repository.WalletTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class WalletService {

        private final WalletRepository walletRepository;
        private final WalletTransactionRepository transactionRepository;
        private final UserRepository userRepository;

        /**
         * Reserve funds for a bid using PESSIMISTIC LOCKING to prevent double-spending
         * 
         * @param userId User ID
         * @param amount Amount to reserve
         * @throws WalletNotFoundException    if wallet doesn't exist
         * @throws InsufficientFundsException if insufficient balance
         */
        public void reserveFunds(Long userId, BigDecimal amount) {
                log.info("Reserving {} VND for user {}", amount, userId);

                // CRITICAL: Use pessimistic lock to prevent concurrent modifications
                Wallet wallet = walletRepository.findByUserIdWithLock(userId)
                                .orElseThrow(() -> new WalletNotFoundException(userId));

                // Calculate available balance (total - reserved)
                BigDecimal availableBalance = wallet.getBalance().subtract(wallet.getReservedBalance());

                // Validate sufficient funds
                if (availableBalance.compareTo(amount) < 0) {
                        log.warn("Insufficient funds for user {}. Required: {}, Available: {}",
                                        userId, amount, availableBalance);
                        throw new InsufficientFundsException(userId, amount, availableBalance);
                }

                // Capture balance before transaction
                BigDecimal balanceBefore = wallet.getBalance();

                // Reserve funds (increase reserved_balance)
                wallet.setReservedBalance(wallet.getReservedBalance().add(amount));

                // Save wallet (optimistic lock version will auto-increment)
                walletRepository.save(wallet);

                // Log transaction for audit trail
                WalletTransaction transaction = WalletTransaction.builder()
                                .wallet(wallet)
                                .user(wallet.getUser())
                                .transactionType(TransactionType.BID_RESERVE)
                                .amount(amount)
                                .balanceBefore(balanceBefore)
                                .balanceAfter(wallet.getBalance()) // Balance unchanged, only reserved
                                .status(TransactionStatus.COMPLETED)
                                .description(String.format("Reserved %s VND for bid", amount))
                                .build();

                transactionRepository.save(transaction);

                log.info("Successfully reserved {} VND for user {}. New reserved balance: {}",
                                amount, userId, wallet.getReservedBalance());
        }

        /**
         * Release reserved funds (when user is outbid or auction ends)
         * 
         * @param userId User ID
         * @param amount Amount to release
         * @throws WalletNotFoundException if wallet doesn't exist
         */
        public void releaseFunds(Long userId, BigDecimal amount) {
                log.info("Releasing {} VND for user {}", amount, userId);

                // Use pessimistic lock
                Wallet wallet = walletRepository.findByUserIdWithLock(userId)
                                .orElseThrow(() -> new WalletNotFoundException(userId));

                BigDecimal balanceBefore = wallet.getBalance();

                // Release reserved funds (decrease reserved_balance)
                wallet.setReservedBalance(wallet.getReservedBalance().subtract(amount));

                // Ensure reserved balance doesn't go negative
                if (wallet.getReservedBalance().compareTo(BigDecimal.ZERO) < 0) {
                        log.error("Reserved balance would go negative for user {}! Setting to 0", userId);
                        wallet.setReservedBalance(BigDecimal.ZERO);
                }

                walletRepository.save(wallet);

                // Log transaction
                WalletTransaction transaction = WalletTransaction.builder()
                                .wallet(wallet)
                                .user(wallet.getUser())
                                .transactionType(TransactionType.BID_RELEASE)
                                .amount(amount.negate()) // Negative for release
                                .balanceBefore(balanceBefore)
                                .balanceAfter(wallet.getBalance())
                                .status(TransactionStatus.COMPLETED)
                                .description(String.format("Released %s VND from bid reserve", amount))
                                .build();

                transactionRepository.save(transaction);

                log.info("Successfully released {} VND for user {}. New reserved balance: {}",
                                amount, userId, wallet.getReservedBalance());
        }

        /**
         * Deduct funds from wallet (when user wins auction)
         * 
         * @param userId User ID
         * @param amount Amount to deduct
         */
        public void deductFunds(Long userId, BigDecimal amount) {
                log.info("Deducting {} VND from user {}", amount, userId);

                Wallet wallet = walletRepository.findByUserIdWithLock(userId)
                                .orElseThrow(() -> new WalletNotFoundException(userId));

                BigDecimal balanceBefore = wallet.getBalance();

                // Deduct from both balance and reserved_balance
                wallet.setBalance(wallet.getBalance().subtract(amount));
                wallet.setReservedBalance(wallet.getReservedBalance().subtract(amount));

                walletRepository.save(wallet);

                // Log transaction
                WalletTransaction transaction = WalletTransaction.builder()
                                .wallet(wallet)
                                .user(wallet.getUser())
                                .transactionType(TransactionType.PAYMENT)
                                .amount(amount.negate())
                                .balanceBefore(balanceBefore)
                                .balanceAfter(wallet.getBalance())
                                .status(TransactionStatus.COMPLETED)
                                .description(String.format("Payment for auction win: %s VND", amount))
                                .build();

                transactionRepository.save(transaction);

                log.info("Successfully deducted {} VND from user {}. New balance: {}",
                                amount, userId, wallet.getBalance());
        }

        /**
         * Add funds to wallet (when seller receives payment)
         * 
         * @param userId User ID
         * @param amount Amount to add
         */
        public void addFunds(Long userId, BigDecimal amount) {
                log.info("Adding {} VND to user {}", amount, userId);

                Wallet wallet = walletRepository.findByUserIdWithLock(userId)
                                .orElseThrow(() -> new WalletNotFoundException(userId));

                BigDecimal balanceBefore = wallet.getBalance();

                // Add to balance
                wallet.setBalance(wallet.getBalance().add(amount));

                walletRepository.save(wallet);

                // Log transaction
                WalletTransaction transaction = WalletTransaction.builder()
                                .wallet(wallet)
                                .user(wallet.getUser())
                                .transactionType(TransactionType.PAYOUT)
                                .amount(amount)
                                .balanceBefore(balanceBefore)
                                .balanceAfter(wallet.getBalance())
                                .status(TransactionStatus.COMPLETED)
                                .description(String.format("Payout from auction: %s VND", amount))
                                .build();

                transactionRepository.save(transaction);

                log.info("Successfully added {} VND to user {}. New balance: {}",
                                amount, userId, wallet.getBalance());
        }

        /**
         * Deposit funds to wallet (for testing/manual deposits)
         * Creates wallet if it doesn't exist
         * 
         * @param userId User ID
         * @param amount Amount to deposit
         * @return Updated wallet
         */
        public Wallet deposit(Long userId, BigDecimal amount) {
                log.info("Depositing {} VND to user {}", amount, userId);

                // Try to find existing wallet
                Wallet wallet = walletRepository.findByUserId(userId)
                                .orElseGet(() -> {
                                        // Create new wallet if doesn't exist
                                        log.info("Creating new wallet for user {}", userId);
                                        User user = userRepository.findById(userId)
                                                        .orElseThrow(() -> new RuntimeException(
                                                                        "User not found: " + userId));

                                        Wallet newWallet = Wallet.builder()
                                                        .user(user)
                                                        .balance(BigDecimal.ZERO)
                                                        .reservedBalance(BigDecimal.ZERO)
                                                        .currency("VND")
                                                        .build();

                                        return walletRepository.save(newWallet);
                                });

                BigDecimal balanceBefore = wallet.getBalance();

                // Add deposit amount to balance
                wallet.setBalance(wallet.getBalance().add(amount));

                walletRepository.save(wallet);

                // Log transaction
                WalletTransaction transaction = WalletTransaction.builder()
                                .wallet(wallet)
                                .user(wallet.getUser())
                                .transactionType(TransactionType.DEPOSIT)
                                .amount(amount)
                                .balanceBefore(balanceBefore)
                                .balanceAfter(wallet.getBalance())
                                .status(TransactionStatus.COMPLETED)
                                .description(String.format("Manual deposit: %s VND", amount))
                                .build();

                transactionRepository.save(transaction);

                log.info("Successfully deposited {} VND to user {}. New balance: {}",
                                amount, userId, wallet.getBalance());

                return wallet;
        }

        /**
         * Get wallet by user ID
         */
        @Transactional(readOnly = true)
        public Wallet getWalletByUserId(Long userId) {
                return walletRepository.findByUserId(userId)
                                .orElseThrow(() -> new WalletNotFoundException(userId));
        }

        /**
         * Get available balance (total - reserved)
         */
        @Transactional(readOnly = true)
        public BigDecimal getAvailableBalance(Long userId) {
                Wallet wallet = getWalletByUserId(userId);
                return wallet.getBalance().subtract(wallet.getReservedBalance());
        }
}
