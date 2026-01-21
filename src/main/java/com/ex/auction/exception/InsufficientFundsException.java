package com.ex.auction.exception;

public class InsufficientFundsException extends RuntimeException {

    public InsufficientFundsException(String message) {
        super(message);
    }

    public InsufficientFundsException(Long userId, java.math.BigDecimal required, java.math.BigDecimal available) {
        super(String.format("User %d has insufficient funds. Required: %s, Available: %s",
                userId, required, available));
    }
}
