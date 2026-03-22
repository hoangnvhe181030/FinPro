package com.ex.auction.service;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Bid;
import com.ex.auction.domain.entity.Product;
import com.ex.auction.domain.entity.User;
import com.ex.auction.domain.enums.AuctionStatus;
import com.ex.auction.domain.enums.BidStatus;
import com.ex.auction.domain.enums.ProductCondition;
import com.ex.auction.dto.AuctionResponse;
import com.ex.auction.dto.AuctionUpdateMessage;
import com.ex.auction.exception.AuctionEndedException;
import com.ex.auction.exception.AuctionNotFoundException;
import com.ex.auction.exception.InvalidBidAmountException;
import com.ex.auction.repository.AuctionRepository;
import com.ex.auction.repository.BidRepository;
import com.ex.auction.repository.ProductRepository;
import com.ex.auction.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class AuctionService {

    private final AuctionRepository auctionRepository;
    private final BidRepository bidRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final WalletService walletService;
    private final SimpMessagingTemplate messagingTemplate;

    private static final int SOFT_CLOSE_MINUTES = 5;

    /**
     * Place a bid on an auction with soft-close logic
     * 
     * @param auctionId Auction ID
     * @param userId    User ID
     * @param bidAmount Bid amount
     * @return Created bid
     */
    public Bid placeBid(Long auctionId, Long userId, BigDecimal bidAmount) {
        log.info("Placing bid: auctionId={}, userId={}, amount={}", auctionId, userId, bidAmount);

        LocalDateTime bidTime = LocalDateTime.now();

        // 1. Fetch auction
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new AuctionNotFoundException(auctionId));

        // 2. Validate auction is ACTIVE
        if (auction.getStatus() != AuctionStatus.ACTIVE) {
            throw new AuctionEndedException("Auction is not active: " + auction.getStatus());
        }

        // 3. Check if auction has ended
        if (bidTime.isAfter(auction.getEndTime())) {
            throw new AuctionEndedException(auctionId);
        }

        // 4. Calculate minimum bid amount (current price + increment)
        BigDecimal minimumBid = auction.getCurrentPrice().add(auction.getBidIncrement());

        // 5. Validate bid amount
        if (bidAmount.compareTo(minimumBid) < 0) {
            log.warn("Bid amount {} is below minimum required {}", bidAmount, minimumBid);
            throw new InvalidBidAmountException(bidAmount, minimumBid);
        }

        // 6. SOFT-CLOSE: Check if bid is within last 5 minutes
        long minutesUntilEnd = ChronoUnit.MINUTES.between(bidTime, auction.getEndTime());
        boolean softCloseTriggered = false;

        if (minutesUntilEnd >= 0 && minutesUntilEnd < SOFT_CLOSE_MINUTES) {
            log.info("Soft-close triggered! Bid placed with {} minutes remaining. Extending auction by {} minutes",
                    minutesUntilEnd, SOFT_CLOSE_MINUTES);

            // Extend end_time by 5 minutes
            auction.setEndTime(auction.getEndTime().plusMinutes(SOFT_CLOSE_MINUTES));
            softCloseTriggered = true;

            log.info("Auction {} end time extended to {}", auctionId, auction.getEndTime());
        }

        // 7. OUTBID LOGIC: Get previous highest bidder (before placing new bid)
        Bid previousHighestBid = bidRepository.findHighestBid(auctionId)
                .orElse(null);

        // 8. Reserve funds for NEW bidder BEFORE creating bid (CRITICAL for atomicity)
        try {
            walletService.reserveFunds(userId, bidAmount);
        } catch (Exception e) {
            log.error("Failed to reserve funds for user {}: {}", userId, e.getMessage());
            throw e; // Rollback transaction
        }

        // 9. Fetch user
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));

        // 10. Create and save NEW bid
        Bid bid = Bid.builder()
                .auction(auction)
                .user(user)
                .bidAmount(bidAmount)
                .bidStatus(BidStatus.ACCEPTED)
                .bidTime(bidTime)
                .build();

        bid = bidRepository.save(bid);

        // 11. Update auction current price and total bids
        auction.setCurrentPrice(bidAmount);
        auction.setTotalBids(auction.getTotalBids() + 1);

        auctionRepository.save(auction);

        // 12. OUTBID LOGIC: Release funds for PREVIOUS bidder and mark as OUTBID
        if (previousHighestBid != null) {
            try {
                Long previousUserId = previousHighestBid.getUser().getUserId();
                BigDecimal previousAmount = previousHighestBid.getBidAmount();

                // Release reserved funds
                walletService.releaseFunds(previousUserId, previousAmount);

                log.info("Released {} VND for outbid user {}", previousAmount, previousUserId);

                // Note: We DON'T update bid status here because Bid entity is immutable
                // The bid status remains ACCEPTED in the database
                // Only the settlement process will differentiate winner from losers

            } catch (Exception e) {
                log.error("Failed to release funds for previous bidder: {}", e.getMessage(), e);
                // Don't throw - new bid is already saved, just log the error
            }
        }

        // 13. Broadcast real-time update to all connected WebSocket clients
        broadcastAuctionUpdate(auction, bid, user, softCloseTriggered);

        log.info("Bid placed successfully: bidId={}, amount={}, softCloseTriggered={}",
                bid.getBidId(), bidAmount, softCloseTriggered);

        return bid;
    }

    /**
     * Broadcast auction update via WebSocket to all subscribed clients
     */
    private void broadcastAuctionUpdate(Auction auction, Bid bid, User user, boolean softCloseTriggered) {
        String destination = "/topic/auctions/" + auction.getAuctionId();

        // Send price update message
        AuctionUpdateMessage priceUpdate = AuctionUpdateMessage.priceUpdate(
                auction.getAuctionId(),
                auction.getCurrentPrice(),
                user.getUsername(),
                auction.getTotalBids());

        messagingTemplate.convertAndSend(destination, priceUpdate);
        log.info("WebSocket broadcast sent to {}: {}", destination, priceUpdate);

        // If soft-close was triggered, send additional message
        if (softCloseTriggered) {
            AuctionUpdateMessage softCloseMessage = AuctionUpdateMessage.softCloseExtended(
                    auction.getAuctionId(),
                    auction.getEndTime(),
                    auction.getTotalBids());

            messagingTemplate.convertAndSend(destination, softCloseMessage);
            log.info("WebSocket soft-close notification sent to {}", destination);
        }
    }

    /**
     * Create a new auction programmatically
     *
     * @param sellerId        Seller user ID
     * @param startingPrice   Starting price
     * @param bidIncrement    Bid increment
     * @param durationMinutes Auction duration in minutes
     * @param reservePrice    Optional reserve price
     * @return Created auction
     */
    public Auction createAuction(Long productId, Long sellerId,
            BigDecimal startingPrice, BigDecimal bidIncrement,
            Long durationMinutes, BigDecimal reservePrice) {
        log.info("Creating auction: product={}, seller={}, startPrice={}, duration={} mins",
                productId, sellerId, startingPrice, durationMinutes);

        // Fetch seller
        User seller = userRepository.findById(sellerId)
                .orElseThrow(() -> new RuntimeException("Seller not found: " + sellerId));

        // For simplicity, create a simple product on-the-fly
        // In production: Link to existing product or create via ProductService
        Product product = productRepository.findByProductId(productId)
                .orElseThrow(() -> new RuntimeException("Product not found: " + productId));
        // Note: In real app, save product to DB first with category
        // For testing purposes, we create inline

        // Calculate auction times
        LocalDateTime startTime = LocalDateTime.now();
        LocalDateTime endTime = startTime.plusMinutes(durationMinutes);

        // Create auction
        Auction auction = Auction.builder()
                .product(product)
                .seller(seller)
                .startingPrice(startingPrice)
                .currentPrice(startingPrice)
                .reservePrice(reservePrice != null ? reservePrice : BigDecimal.ZERO)
                .bidIncrement(bidIncrement)
                .startTime(startTime)
                .endTime(endTime)
                .originalEndTime(endTime)
                .status(AuctionStatus.ACTIVE)
                .totalBids(0)
                .build();

        auction = auctionRepository.save(auction);

        log.info("Auction created successfully: auctionId={}, endTime={}",
                auction.getAuctionId(), auction.getEndTime());

        return auction;
    }

    /**
     * Get auction by ID
     */
    @Transactional(readOnly = true)
    public Auction getAuctionById(Long auctionId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new AuctionNotFoundException(auctionId));
        auction.getProduct().getProductName(); // Trigger load
        auction.getSeller().getUsername();
        return auction;
    }

    /**
     * Get active auctions (not ended)
     */
    @Transactional(readOnly = true)
    public List<Auction> getActiveAuctions(AuctionStatus status, LocalDateTime now) {
        return auctionRepository.findActiveAuctions(status, now);
    }

    /**
     * Get current highest bid for an auction
     */
    @Transactional(readOnly = true)
    public Bid getHighestBid(Long auctionId) {
        return bidRepository.findHighestBid(auctionId)
                .orElse(null);
    }

    /**
     * Get all bids for an auction
     */
    @Transactional(readOnly = true)
    public List<Bid> getAuctionBids(Long auctionId) {
        return bidRepository.findByAuctionIdOrderByBidTimeDesc(auctionId);
    }

    /**
     * Check if soft-close should be triggered
     * 
     * @param auction Auction
     * @param bidTime Bid time
     * @return true if soft-close triggered
     */
    private boolean shouldTriggerSoftClose(Auction auction, LocalDateTime bidTime) {
        long minutesUntilEnd = ChronoUnit.MINUTES.between(bidTime, auction.getEndTime());
        return minutesUntilEnd >= 0 && minutesUntilEnd < SOFT_CLOSE_MINUTES;
    }

    /**
     * Convert Auction entity to AuctionResponse DTO
     * Made public for UserController access
     */
    public AuctionResponse toResponse(Auction auction) {
        return AuctionResponse.builder()
                .id(auction.getAuctionId())
                .productName(auction.getProduct().getProductName())
                .sellerName(auction.getSeller().getUsername())
                .startingPrice(auction.getStartingPrice())
                .currentPrice(auction.getCurrentPrice())
                .bidIncrement(auction.getBidIncrement())
                .startTime(auction.getStartTime())
                .endTime(auction.getEndTime())
                .status(auction.getStatus())
                .totalBids(auction.getTotalBids())
                .build();
    }
}
