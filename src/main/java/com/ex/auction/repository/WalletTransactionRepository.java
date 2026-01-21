package com.ex.auction.repository;

import com.ex.auction.domain.entity.WalletTransaction;
import com.ex.auction.domain.enums.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, Long> {

    // Fixed: Wallet entity has 'walletId' not 'id'
    @Query("SELECT wt FROM WalletTransaction wt WHERE wt.wallet.walletId = :walletId ORDER BY wt.createdAt DESC")
    List<WalletTransaction> findByWalletIdOrderByCreatedAtDesc(@Param("walletId") Long walletId);

    // Fixed: User entity has 'userId' not 'id'
    @Query("SELECT wt FROM WalletTransaction wt WHERE wt.user.userId = :userId ORDER BY wt.createdAt DESC")
    List<WalletTransaction> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId);

    // Fixed: Auction entity has 'auctionId' not 'id'
    @Query("SELECT wt FROM WalletTransaction wt WHERE wt.auction.auctionId = :auctionId")
    List<WalletTransaction> findByAuctionId(@Param("auctionId") Long auctionId);

    List<WalletTransaction> findByTransactionType(TransactionType transactionType);
}
