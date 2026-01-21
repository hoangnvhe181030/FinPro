package com.ex.auction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuctionUpdateMessage {

    private String type; // PRICE_UPDATE, BID_PLACED, SOFT_CLOSE_EXTENDED, AUCTION_ENDED
    private Long auctionId;
    private BigDecimal newPrice;
    private String bidder; // Username who placed the bid
    private LocalDateTime timestamp;
    private Integer totalBids;
    private LocalDateTime endTime; // For soft-close updates

    // Static factory methods for common message types

    public static AuctionUpdateMessage priceUpdate(Long auctionId, BigDecimal newPrice, String bidder,
            Integer totalBids) {
        return AuctionUpdateMessage.builder()
                .type("PRICE_UPDATE")
                .auctionId(auctionId)
                .newPrice(newPrice)
                .bidder(bidder)
                .totalBids(totalBids)
                .timestamp(LocalDateTime.now())
                .build();
    }

    public static AuctionUpdateMessage softCloseExtended(Long auctionId, LocalDateTime newEndTime, Integer totalBids) {
        return AuctionUpdateMessage.builder()
                .type("SOFT_CLOSE_EXTENDED")
                .auctionId(auctionId)
                .endTime(newEndTime)
                .totalBids(totalBids)
                .timestamp(LocalDateTime.now())
                .build();
    }

    public static AuctionUpdateMessage auctionEnded(Long auctionId, BigDecimal finalPrice, String winner) {
        return AuctionUpdateMessage.builder()
                .type("AUCTION_ENDED")
                .auctionId(auctionId)
                .newPrice(finalPrice)
                .bidder(winner)
                .timestamp(LocalDateTime.now())
                .build();
    }
}
