package com.ex.auction.controller;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Favorite;
import com.ex.auction.domain.entity.User;
import com.ex.auction.dto.AuctionResponse;
import com.ex.auction.mapper.AuctionMapper;
import com.ex.auction.repository.AuctionRepository;
import com.ex.auction.repository.FavoriteRepository;
import com.ex.auction.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users/{userId}/favorites")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class FavoriteController {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final AuctionRepository auctionRepository;
    private final AuctionMapper auctionMapper;

    /**
     * GET /api/users/{userId}/favorites - Get user's favorite auctions
     */
    @GetMapping
    public ResponseEntity<List<AuctionResponse>> getFavorites(@PathVariable Long userId) {
        log.info("GET /api/users/{}/favorites", userId);

        List<Favorite> favorites = favoriteRepository.findByUserUserId(userId);
        List<AuctionResponse> response = favorites.stream()
                .map(f -> auctionMapper.toAuctionResponse(f.getAuction()))
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/users/{userId}/favorites/{auctionId} - Add to favorites
     */
    @PostMapping("/{auctionId}")
    public ResponseEntity<Map<String, Object>> addFavorite(
            @PathVariable Long userId,
            @PathVariable Long auctionId) {
        log.info("POST /api/users/{}/favorites/{}", userId, auctionId);

        if (favoriteRepository.existsByUserUserIdAndAuctionAuctionId(userId, auctionId)) {
            return ResponseEntity.ok(Map.of("message", "Already in favorites", "isFavorite", true));
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("Auction not found: " + auctionId));

        Favorite favorite = Favorite.builder()
                .user(user)
                .auction(auction)
                .build();
        favoriteRepository.save(favorite);

        return ResponseEntity.ok(Map.of("message", "Added to favorites", "isFavorite", true));
    }

    /**
     * DELETE /api/users/{userId}/favorites/{auctionId} - Remove from favorites
     */
    @DeleteMapping("/{auctionId}")
    @Transactional
    public ResponseEntity<Map<String, Object>> removeFavorite(
            @PathVariable Long userId,
            @PathVariable Long auctionId) {
        log.info("DELETE /api/users/{}/favorites/{}", userId, auctionId);

        favoriteRepository.deleteByUserUserIdAndAuctionAuctionId(userId, auctionId);

        return ResponseEntity.ok(Map.of("message", "Removed from favorites", "isFavorite", false));
    }

    /**
     * GET /api/users/{userId}/favorites/{auctionId}/check - Check if auction is favorited
     */
    @GetMapping("/{auctionId}/check")
    public ResponseEntity<Map<String, Boolean>> checkFavorite(
            @PathVariable Long userId,
            @PathVariable Long auctionId) {
        boolean isFavorite = favoriteRepository.existsByUserUserIdAndAuctionAuctionId(userId, auctionId);
        return ResponseEntity.ok(Map.of("isFavorite", isFavorite));
    }
}
