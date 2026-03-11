package com.ex.auction.repository;

import com.ex.auction.domain.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    List<Favorite> findByUserUserId(Long userId);

    Optional<Favorite> findByUserUserIdAndAuctionAuctionId(Long userId, Long auctionId);

    boolean existsByUserUserIdAndAuctionAuctionId(Long userId, Long auctionId);

    void deleteByUserUserIdAndAuctionAuctionId(Long userId, Long auctionId);
}
