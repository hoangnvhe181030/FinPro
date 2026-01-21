package com.ex.auction.exception;

public class WalletNotFoundException extends RuntimeException {

    public WalletNotFoundException(String message) {
        super(message);
    }

    public WalletNotFoundException(Long userId) {
        super(String.format("Wallet not found for user %d", userId));
    }
}
