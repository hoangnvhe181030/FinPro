package com.ex.auction.repository;

import com.ex.auction.domain.entity.BidEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BidEventRepository extends JpaRepository<BidEvent, Long> {

    // Fixed: Bid entity has 'bidId' not 'id'
    @Query("SELECT be FROM BidEvent be WHERE be.bid.bidId = :bidId ORDER BY be.eventTime DESC")
    List<BidEvent> findByBidIdOrderByEventTimeDesc(@Param("bidId") Long bidId);

    List<BidEvent> findByProcessedFalseOrderByEventTimeAsc();
}
