package com.ex.auction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WalletResponse {

    private Long userId;
    private Long walletId;
    private BigDecimal balance;
    private BigDecimal reservedBalance;
    private BigDecimal availableBalance;
    private String currency;
}
