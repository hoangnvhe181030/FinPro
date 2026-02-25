package com.ex.auction.repository;

import com.ex.auction.domain.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    // Product entity has no seller field
    // If you need to query by seller, add seller field to Product entity first

    // Find product by ID (for existence check)
    Optional<Product> findByProductId(Long productId);
}
