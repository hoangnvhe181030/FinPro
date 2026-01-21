package com.ex.auction.exception;

public class AuctionNotFoundException extends RuntimeException {

    public AuctionNotFoundException(String message) {
        super(message);
    }

    public AuctionNotFoundException(Long auctionId) {
        super(String.format("Auction %d not found", auctionId));
    }
}
