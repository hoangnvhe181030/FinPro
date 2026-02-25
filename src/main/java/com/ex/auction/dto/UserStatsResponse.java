package com.ex.auction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserStatsResponse {
    private Long totalAuctionsCreated;
    private Long activeAuctions;
    private Long totalBids;
    private Long auctionsWon;
    private Double totalSpent;
    private Double totalEarned;
}
