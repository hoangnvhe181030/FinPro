package com.ex.auction.repository;

import com.ex.auction.domain.entity.Bid;
import com.ex.auction.domain.enums.BidStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BidRepository extends JpaRepository<Bid, Long> {

    // Fixed: Auction entity has 'auctionId' not 'id'
    @Query("SELECT b FROM Bid b WHERE b.auction.auctionId = :auctionId ORDER BY b.bidTime DESC")
    List<Bid> findByAuctionIdOrderByBidTimeDesc(@Param("auctionId") Long auctionId);

    // Fixed: User entity has 'userId' not 'id'
    @Query("SELECT b FROM Bid b WHERE b.user.userId = :userId ORDER BY b.bidTime DESC")
    List<Bid> findByUserIdOrderByBidTimeDesc(@Param("userId") Long userId);

    @Query("SELECT b FROM Bid b WHERE b.auction.auctionId = :auctionId AND b.bidStatus = :status ORDER BY b.bidAmount DESC, b.bidTime ASC")
    List<Bid> findLeaderboard(@Param("auctionId") Long auctionId, @Param("status") BidStatus status);

    // Fixed: Use native query with FETCH FIRST to limit to 1 result (Oracle SQL)
    // Prevents NonUniqueResultException when multiple bids have same amount
    @Query(value = "SELECT * FROM bids WHERE auction_id = :auctionId " +
            "ORDER BY bid_amount DESC, bid_time ASC " +
            "FETCH FIRST 1 ROW ONLY", nativeQuery = true)
    Optional<Bid> findHighestBid(@Param("auctionId") Long auctionId);

    // Find bids by bidder user ID
    @Query("SELECT b FROM Bid b WHERE b.user.userId = :userId")
    List<Bid> findByBidderUserId(@Param("userId") Long userId);

    // Fixed: Auction entity has 'auctionId' not 'id'
    @Query("SELECT COUNT(b) FROM Bid b WHERE b.auction.auctionId = :auctionId")
    long countByAuctionId(@Param("auctionId") Long auctionId);
}
