package com.ex.auction.scheduler;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.repository.AuctionRepository;
import com.ex.auction.service.SettlementService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class AuctionScheduler {

    private final AuctionRepository auctionRepository;
    private final SettlementService settlementService;

    /**
     * Scheduled job to settle ended auctions
     * Runs every minute (60000 ms)
     */
    @Scheduled(fixedRate = 60000)
    public void settleEndedAuctions() {
        log.info("Running auction settlement scheduler...");

        try {
            // Find all active auctions that have ended
            List<Auction> endedAuctions = auctionRepository.findExpiredAuctions(LocalDateTime.now());

            if (endedAuctions.isEmpty()) {
                log.debug("No ended auctions found for settlement");
                return;
            }

            log.info("Found {} ended auctions to settle", endedAuctions.size());

            // Settle each auction independently
            for (Auction auction : endedAuctions) {
                try {
                    // FIXED: Don't access lazy-loaded Product - causes LazyInitializationException
                    // The Hibernate session is closed after settling
                    log.info("Settling auction {} (ended at {})",
                            auction.getAuctionId(),
                            auction.getEndTime());

                    settlementService.settleEndedAuction(auction.getAuctionId());

                } catch (Exception e) {
                    // Log error but continue with other auctions
                    log.error("Failed to settle auction {}: {}",
                            auction.getAuctionId(), e.getMessage(), e);
                    // Don't rethrow - continue with next auction
                }
            }

            log.info("Auction settlement scheduler completed");

        } catch (Exception e) {
            log.error("Error in auction settlement scheduler: {}", e.getMessage(), e);
        }
    }
}
