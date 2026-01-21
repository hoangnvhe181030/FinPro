package com.ex.auction.dto;

import com.ex.auction.domain.enums.AuctionStatus;
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
public class AuctionResponse {

    private Long id;
    private String productName;
    private String sellerName;
    private BigDecimal currentPrice;
    private BigDecimal startingPrice;
    private BigDecimal bidIncrement;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private LocalDateTime originalEndTime;
    private AuctionStatus status;
    private Integer totalBids;
}
