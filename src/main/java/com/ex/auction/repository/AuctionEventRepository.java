package com.ex.auction.repository;

import com.ex.auction.domain.entity.AuctionEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuctionEventRepository extends JpaRepository<AuctionEvent, Long> {

    // Fixed: Auction entity has 'auctionId' not 'id'
    @Query("SELECT ae FROM AuctionEvent ae WHERE ae.auction.auctionId = :auctionId ORDER BY ae.eventTime DESC")
    List<AuctionEvent> findByAuctionIdOrderByEventTimeDesc(@Param("auctionId") Long auctionId);

    List<AuctionEvent> findByProcessedFalseOrderByEventTimeAsc();
}
