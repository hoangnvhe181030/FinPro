package com.ex.auction.controller;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Bid;
import com.ex.auction.domain.enums.AuctionStatus;
import com.ex.auction.dto.AuctionCreateRequest;
import com.ex.auction.dto.AuctionResponse;
import com.ex.auction.dto.BidRequest;
import com.ex.auction.dto.BidResponse;
import com.ex.auction.mapper.AuctionMapper;
import com.ex.auction.service.AuctionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class AuctionController {

    private final AuctionService auctionService;
    private final AuctionMapper auctionMapper;

    /**
     * GET /api/auctions - List active auctions with pagination
     */
    @GetMapping("/auctions")
    public ResponseEntity<List<AuctionResponse>> getActiveAuctions(
            @PageableDefault(size = 20) Pageable pageable) {

        log.info("GET /api/auctions - page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());

        // Get active auctions (status = ACTIVE and not ended)
        List<Auction> auctions = auctionService.getActiveAuctions(
                AuctionStatus.ACTIVE,
                LocalDateTime.now());

        List<AuctionResponse> response = auctions.stream()
                .map(auctionMapper::toAuctionResponse)
                .collect(Collectors.toList());

        log.info("Returning {} active auctions", response.size());

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/auctions/search - Search auctions by keyword, category, price range
     */
    @GetMapping("/auctions/search")
    public ResponseEntity<List<AuctionResponse>> searchAuctions(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "newest") String sort) {

        log.info("GET /api/auctions/search - keyword: {}, category: {}, price: {}-{}", keyword, categoryId, minPrice, maxPrice);

        List<Auction> auctions;
        if (status != null && status.equalsIgnoreCase("ENDED")) {
            auctions = auctionService.getActiveAuctions(AuctionStatus.ENDED, LocalDateTime.now().plusYears(100));
        } else {
            auctions = auctionService.getActiveAuctions(AuctionStatus.ACTIVE, LocalDateTime.now());
        }

        // Filter by keyword
        if (keyword != null && !keyword.isEmpty()) {
            String lowerKeyword = keyword.toLowerCase();
            auctions = auctions.stream()
                    .filter(a -> a.getProduct().getProductName().toLowerCase().contains(lowerKeyword))
                    .collect(Collectors.toList());
        }

        // Filter by category
        if (categoryId != null) {
            auctions = auctions.stream()
                    .filter(a -> a.getProduct().getCategory() != null &&
                            a.getProduct().getCategory().getCategoryId().equals(categoryId))
                    .collect(Collectors.toList());
        }

        // Filter by price range
        if (minPrice != null) {
            auctions = auctions.stream()
                    .filter(a -> a.getCurrentPrice().doubleValue() >= minPrice)
                    .collect(Collectors.toList());
        }
        if (maxPrice != null) {
            auctions = auctions.stream()
                    .filter(a -> a.getCurrentPrice().doubleValue() <= maxPrice)
                    .collect(Collectors.toList());
        }

        // Sort
        switch (sort.toLowerCase()) {
            case "price_asc":
                auctions.sort((a, b) -> a.getCurrentPrice().compareTo(b.getCurrentPrice()));
                break;
            case "price_desc":
                auctions.sort((a, b) -> b.getCurrentPrice().compareTo(a.getCurrentPrice()));
                break;
            case "bids":
                auctions.sort((a, b) -> b.getTotalBids().compareTo(a.getTotalBids()));
                break;
            case "ending_soon":
                auctions.sort((a, b) -> a.getEndTime().compareTo(b.getEndTime()));
                break;
            default: // newest
                auctions.sort((a, b) -> b.getStartTime().compareTo(a.getStartTime()));
        }

        List<AuctionResponse> response = auctions.stream()
                .map(auctionMapper::toAuctionResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/auctions/{id} - Get auction detail
     */
    @GetMapping("/auctions/{id}")
    public ResponseEntity<AuctionResponse> getAuctionById(@PathVariable Long id) {
        log.info("GET /api/auctions/{}", id);

        Auction auction = auctionService.getAuctionById(id);
        AuctionResponse response = auctionMapper.toAuctionResponse(auction);

        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/auctions/{auctionId}/bids - Get bid history for an auction
     */
    @GetMapping("/auctions/{auctionId}/bids")
    public ResponseEntity<List<BidResponse>> getAuctionBids(@PathVariable Long auctionId) {
        log.info("GET /api/auctions/{}/bids", auctionId);

        List<Bid> bids = auctionService.getAuctionBids(auctionId);

        List<BidResponse> response = bids.stream()
                .map(auctionMapper::toBidResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/auctions - Create new auction
     */
    @PostMapping("/auctions")
    public ResponseEntity<AuctionResponse> createAuction(
            @Valid @RequestBody AuctionCreateRequest request,
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "1") Long sellerId) {

        log.info("POST /api/auctions - seller: {}, product: {}, startPrice: {}, duration: {} mins",
                sellerId, request.getProductId(), request.getStartingPrice(), request.getDurationMinutes());

        Auction auction = auctionService.createAuction(
                request.getProductId(),
                sellerId,
                request.getStartingPrice(),
                request.getBidIncrement(),
                request.getDurationMinutes(),
                request.getReservePrice());

        AuctionResponse response = auctionMapper.toAuctionResponse(auction);

        log.info("Auction created: auctionId={}", auction.getAuctionId());

        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/bids - Place a bid with automatic retry on optimistic locking
     * failure
     * 
     * CRITICAL: Retries up to 3 times on OptimisticLockingFailureException
     */
    @PostMapping("/bids")
    @Retryable(retryFor = OptimisticLockingFailureException.class, maxAttempts = 3, backoff = @Backoff(delay = 100, multiplier = 2))
    public ResponseEntity<BidResponse> placeBid(
            @Valid @RequestBody BidRequest request,
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "1") Long userId) {

        log.info("POST /api/bids - userId: {}, auctionId: {}, amount: {}",
                userId, request.getAuctionId(), request.getAmount());

        // Place bid through service (may throw OptimisticLockingFailureException)
        Bid bid = auctionService.placeBid(
                request.getAuctionId(),
                userId,
                request.getAmount());

        BidResponse response = auctionMapper.toBidResponse(bid);

        log.info("Bid placed successfully: bidId={}", bid.getBidId());

        return ResponseEntity.ok(response);
    }
}
