package com.ex.auction.exception;

import com.ex.auction.dto.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    /**
     * Handle Optimistic Locking Failures
     * Returns HTTP 409 Conflict
     */
    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<ErrorResponse> handleOptimisticLockingFailure(
            OptimisticLockingFailureException ex,
            HttpServletRequest request) {

        log.warn("Optimistic locking failure: {}", ex.getMessage());

        ErrorResponse error = ErrorResponse.of(
                "CONCURRENCY_ERROR",
                "Price has changed. Please refresh and try again.",
                request.getRequestURI());

        return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
    }

    /**
     * Handle Insufficient Funds Exception
     * Returns HTTP 400 Bad Request
     */
    @ExceptionHandler(InsufficientFundsException.class)
    public ResponseEntity<ErrorResponse> handleInsufficientFunds(
            InsufficientFundsException ex,
            HttpServletRequest request) {

        log.warn("Insufficient funds: {}", ex.getMessage());

        ErrorResponse error = ErrorResponse.of(
                "INSUFFICIENT_FUNDS",
                ex.getMessage(),
                request.getRequestURI());

        return ResponseEntity.badRequest().body(error);
    }

    /**
     * Handle Auction Ended Exception
     * Returns HTTP 400 Bad Request
     */
    @ExceptionHandler(AuctionEndedException.class)
    public ResponseEntity<ErrorResponse> handleAuctionEnded(
            AuctionEndedException ex,
            HttpServletRequest request) {

        log.warn("Auction ended: {}", ex.getMessage());

        ErrorResponse error = ErrorResponse.of(
                "AUCTION_ENDED",
                ex.getMessage(),
                request.getRequestURI());

        return ResponseEntity.badRequest().body(error);
    }

    /**
     * Handle Invalid Bid Amount Exception
     * Returns HTTP 400 Bad Request
     */
    @ExceptionHandler(InvalidBidAmountException.class)
    public ResponseEntity<ErrorResponse> handleInvalidBidAmount(
            InvalidBidAmountException ex,
            HttpServletRequest request) {

        log.warn("Invalid bid amount: {}", ex.getMessage());

        ErrorResponse error = ErrorResponse.of(
                "INVALID_BID_AMOUNT",
                ex.getMessage(),
                request.getRequestURI());

        return ResponseEntity.badRequest().body(error);
    }

    /**
     * Handle Auction Not Found Exception
     * Returns HTTP 404 Not Found
     */
    @ExceptionHandler(AuctionNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleAuctionNotFound(
            AuctionNotFoundException ex,
            HttpServletRequest request) {

        log.warn("Auction not found: {}", ex.getMessage());

        ErrorResponse error = ErrorResponse.of(
                "AUCTION_NOT_FOUND",
                ex.getMessage(),
                request.getRequestURI());

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    /**
     * Handle Wallet Not Found Exception
     * Returns HTTP 404 Not Found
     */
    @ExceptionHandler(WalletNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleWalletNotFound(
            WalletNotFoundException ex,
            HttpServletRequest request) {

        log.warn("Wallet not found: {}", ex.getMessage());

        ErrorResponse error = ErrorResponse.of(
                "WALLET_NOT_FOUND",
                ex.getMessage(),
                request.getRequestURI());

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    /**
     * Handle Validation Errors
     * Returns HTTP 400 Bad Request
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationErrors(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {

        String message = ex.getBindingResult().getAllErrors().stream()
                .map(error -> error.getDefaultMessage())
                .findFirst()
                .orElse("Validation error");

        log.warn("Validation error: {}", message);

        ErrorResponse error = ErrorResponse.of(
                "VALIDATION_ERROR",
                message,
                request.getRequestURI());

        return ResponseEntity.badRequest().body(error);
    }

    /**
     * Handle all other exceptions
     * Returns HTTP 500 Internal Server Error
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(
            Exception ex,
            HttpServletRequest request) {

        log.error("Unexpected error: ", ex);

        ErrorResponse error = ErrorResponse.of(
                "INTERNAL_SERVER_ERROR",
                "An unexpected error occurred. Please try again later.",
                request.getRequestURI());

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
