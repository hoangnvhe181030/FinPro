package com.ex.auction.controller;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Bid;
import com.ex.auction.domain.entity.User;
import com.ex.auction.domain.enums.AuctionStatus;
import com.ex.auction.domain.enums.BidStatus;
import com.ex.auction.dto.AuctionResponse;
import com.ex.auction.dto.UserStatsResponse;
import com.ex.auction.repository.AuctionRepository;
import com.ex.auction.repository.BidRepository;
import com.ex.auction.repository.UserRepository;
import com.ex.auction.service.AuctionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class UserController {

        private final UserRepository userRepository;
        private final AuctionRepository auctionRepository;
        private final BidRepository bidRepository;
        private final AuctionService auctionService;

        /**
         * Get user stats
         * GET /api/users/{userId}/stats
         */
        @GetMapping("/{userId}/stats")
        public ResponseEntity<UserStatsResponse> getUserStats(@PathVariable Long userId) {
                log.info("GET /api/users/{}/stats", userId);

                // Get auctions created by user
                List<Auction> createdAuctions = auctionRepository.findBySellerUserId(userId);
                long totalAuctionsCreated = createdAuctions.size();
                long activeAuctions = createdAuctions.stream()
                                .filter(a -> a.getStatus() == AuctionStatus.ACTIVE)
                                .count();

                // Get bids by user
                List<Bid> userBids = bidRepository.findByBidderUserId(userId);
                long totalBids = userBids.size();

                // Calculate auctionsWon
                long auctionsWon = auctionRepository.findByWinnerUserId(userId).size();

                // Calculate totalSpent (winning bids)
                double totalSpent = auctionRepository.findByWinnerUserId(userId).stream()
                                .mapToDouble(a -> a.getCurrentPrice().doubleValue())
                                .sum();

                // Calculate totalEarned (sold auctions)
                double totalEarned = createdAuctions.stream()
                                .filter(a -> a.getStatus() == AuctionStatus.ENDED && a.getWinner() != null)
                                .mapToDouble(a -> a.getCurrentPrice().doubleValue())
                                .sum();

                UserStatsResponse stats = UserStatsResponse.builder()
                                .totalAuctionsCreated(totalAuctionsCreated)
                                .activeAuctions(activeAuctions)
                                .totalBids(totalBids)
                                .auctionsWon(auctionsWon)
                                .totalSpent(totalSpent)
                                .totalEarned(totalEarned)
                                .build();

                return ResponseEntity.ok(stats);
        }

        /**
         * Get user's created auctions
         * GET /api/users/{userId}/auctions
         */
        @GetMapping("/{userId}/auctions")
        public ResponseEntity<List<AuctionResponse>> getUserAuctions(@PathVariable Long userId) {
                log.info("GET /api/users/{}/auctions", userId);

                List<Auction> auctions = auctionRepository.findBySellerUserId(userId);
                List<AuctionResponse> response = auctions.stream()
                                .map(auctionService::toResponse)
                                .collect(Collectors.toList());

                return ResponseEntity.ok(response);
        }

        /**
         * Get auctions user is bidding on
         * GET /api/users/{userId}/bidding
         */
        @GetMapping("/{userId}/bidding")
        public ResponseEntity<List<AuctionResponse>> getUserBiddingAuctions(@PathVariable Long userId) {
                log.info("GET /api/users/{}/bidding", userId);

                // Get unique auction IDs from user's bids
                List<Long> auctionIds = bidRepository.findByBidderUserId(userId).stream()
                                .map(bid -> bid.getAuction().getAuctionId())
                                .distinct()
                                .collect(Collectors.toList());

                List<Auction> auctions = auctionRepository.findAllById(auctionIds);
                List<AuctionResponse> response = auctions.stream()
                                .map(auctionService::toResponse)
                                .collect(Collectors.toList());

                return ResponseEntity.ok(response);
        }

        /**
         * Get auctions won by user
         * GET /api/users/{userId}/won
         */
        @GetMapping("/{userId}/won")
        public ResponseEntity<List<AuctionResponse>> getUserWonAuctions(@PathVariable Long userId) {
                log.info("GET /api/users/{}/won", userId);

                List<Auction> auctions = auctionRepository.findByWinnerUserId(userId);
                List<AuctionResponse> response = auctions.stream()
                                .map(auctionService::toResponse)
                                .collect(Collectors.toList());

                return ResponseEntity.ok(response);
        }
}
