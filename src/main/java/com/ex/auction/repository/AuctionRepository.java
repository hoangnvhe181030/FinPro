package com.ex.auction.repository;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.enums.AuctionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AuctionRepository extends JpaRepository<Auction, Long> {

    @Query("SELECT DISTINCT a FROM Auction a " +
            "LEFT JOIN FETCH a.product " +
            "LEFT JOIN FETCH a.seller " +
            "WHERE a.status = :status AND a.endTime > :now " +
            "ORDER BY a.endTime ASC")
    List<Auction> findActiveAuctions(@Param("status") AuctionStatus status,
            @Param("now") LocalDateTime now);

    // Fixed: User entity has 'userId' not 'id'
    @Query("SELECT a FROM Auction a WHERE a.seller.userId = :sellerId")
    List<Auction> findBySellerId(@Param("sellerId") Long sellerId);

    @Query("SELECT a FROM Auction a WHERE a.status = 'ACTIVE' AND a.endTime <= :now")
    List<Auction> findExpiredAuctions(@Param("now") LocalDateTime now);

    // Find auctions by seller (for UserController)
    @Query("SELECT a FROM Auction a WHERE a.seller.userId = :sellerId")
    List<Auction> findBySellerUserId(@Param("sellerId") Long sellerId);

    // Find auctions won by user
    @Query("SELECT a FROM Auction a WHERE a.winner.userId = :userId")
    List<Auction> findByWinnerUserId(@Param("userId") Long userId);
}
