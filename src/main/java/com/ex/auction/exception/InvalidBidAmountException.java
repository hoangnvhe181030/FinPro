package com.ex.auction.exception;

public class InvalidBidAmountException extends RuntimeException {

    public InvalidBidAmountException(String message) {
        super(message);
    }

    public InvalidBidAmountException(java.math.BigDecimal bidAmount, java.math.BigDecimal minimumRequired) {
        super(String.format("Bid amount %s is lower than minimum required: %s",
                bidAmount, minimumRequired));
    }
}
