package com.ex.auction.service;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Bid;
import com.ex.auction.domain.entity.User;
import com.ex.auction.domain.enums.AuctionStatus;
import com.ex.auction.domain.enums.BidStatus;
import com.ex.auction.dto.AuctionUpdateMessage;
import com.ex.auction.exception.AuctionNotFoundException;
import com.ex.auction.repository.AuctionRepository;
import com.ex.auction.repository.BidRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class SettlementService {

    private final AuctionRepository auctionRepository;
    private final BidRepository bidRepository;
    private final WalletService walletService;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Settle an ended auction
     * - Deduct funds from winner
     * - Release funds from all losers
     * - Pay seller
     * - Update auction status to SETTLED
     */
    public void settleEndedAuction(Long auctionId) {
        log.info("Starting settlement for auction {}", auctionId);

        // Fetch auction
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new AuctionNotFoundException(auctionId));

        // Validate auction is ended and not already settled
        if (auction.getStatus() == AuctionStatus.SETTLED) {
            log.warn("Auction {} is already settled, skipping", auctionId);
            return;
        }

        if (auction.getStatus() != AuctionStatus.ACTIVE && auction.getStatus() != AuctionStatus.ENDED) {
            log.warn("Auction {} has invalid status for settlement: {}", auctionId, auction.getStatus());
            return;
        }

        // Get highest bid (winner)
        Bid winningBid = bidRepository.findHighestBid(auctionId)
                .orElse(null);

        if (winningBid == null) {
            log.info("No bids for auction {}, marking as ended without settlement", auctionId);
            auction.setStatus(AuctionStatus.ENDED);
            auctionRepository.save(auction);
            return;
        }

        User winner = winningBid.getUser();
        User seller = auction.getSeller();
        BigDecimal finalPrice = winningBid.getBidAmount();

        log.info("Settling auction {}: Winner={}, FinalPrice={}",
                auctionId, winner.getUsername(), finalPrice);

        try {
            // 1. Deduct funds from winner (both balance and reserved_balance)
            walletService.deductFunds(winner.getUserId(), finalPrice);
            log.info("Deducted {} from winner {}", finalPrice, winner.getUsername());

            // 2. Release reserved funds for all losing bidders
            List<Bid> allBids = bidRepository.findByAuctionIdOrderByBidTimeDesc(auctionId);
            for (Bid bid : allBids) {
                // Skip the winning bid (already deducted)
                if (bid.getBidId().equals(winningBid.getBidId())) {
                    continue;
                }

                // Only release funds for ACCEPTED bids (funds were reserved)
                if (bid.getBidStatus() == BidStatus.ACCEPTED) {
                    walletService.releaseFunds(bid.getUser().getUserId(), bid.getBidAmount());
                    log.info("Released {} for loser {}", bid.getBidAmount(), bid.getUser().getUsername());
                }
            }

            // 3. Pay seller (add to balance)
            walletService.addFunds(seller.getUserId(), finalPrice);
            log.info("Paid {} to seller {}", finalPrice, seller.getUsername());

            // 4. Update auction status
            auction.setWinner(winner);
            auction.setStatus(AuctionStatus.SETTLED);
            auctionRepository.save(auction);

            // 5. Broadcast auction ended message via WebSocket
            broadcastAuctionEnded(auction, winner);

            log.info("Successfully settled auction {}", auctionId);

        } catch (Exception e) {
            log.error("Failed to settle auction {}: {}", auctionId, e.getMessage(), e);
            throw e; // Rollback transaction
        }
    }

    /**
     * Broadcast auction ended message to WebSocket subscribers
     */
    private void broadcastAuctionEnded(Auction auction, User winner) {
        String destination = "/topic/auctions/" + auction.getAuctionId();

        AuctionUpdateMessage endedMessage = AuctionUpdateMessage.auctionEnded(
                auction.getAuctionId(),
                auction.getCurrentPrice(),
                winner.getUsername());

        messagingTemplate.convertAndSend(destination, endedMessage);
        log.info("WebSocket auction ended notification sent to {}", destination);
    }
}
