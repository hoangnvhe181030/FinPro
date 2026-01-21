package com.ex.auction.dto;

import com.ex.auction.domain.enums.BidStatus;
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
public class BidResponse {

    private Long id;
    private Long auctionId;
    private String username;
    private BigDecimal amount;
    private BidStatus status;
    private LocalDateTime time;
}
