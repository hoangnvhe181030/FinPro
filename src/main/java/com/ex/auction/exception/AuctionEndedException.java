package com.ex.auction.exception;

public class AuctionEndedException extends RuntimeException {

    public AuctionEndedException(String message) {
        super(message);
    }

    public AuctionEndedException(Long auctionId) {
        super(String.format("Auction %d has already ended", auctionId));
    }
}
