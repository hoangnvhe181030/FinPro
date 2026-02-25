package com.ex.auction.controller;

import com.ex.auction.domain.entity.Category;
import com.ex.auction.domain.entity.Product;
import com.ex.auction.domain.enums.ProductCondition;
import com.ex.auction.dto.ProductCreateRequest;
import com.ex.auction.repository.ProductRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class ProductController {

    private final ProductRepository productRepository;

    /**
     * Create new product
     * POST /api/products
     *
     * Note: This is a simplified version.
     * In production, you should:
     * 1. Find or create Category entity
     * 2. Associate seller with Product (currently Product has no seller field)
     */
    @PostMapping
    public ResponseEntity<Product> createProduct(
            @RequestHeader("X-User-Id") Long sellerId,
            @Valid @RequestBody ProductCreateRequest request) {
        log.info("POST /api/products - seller: {}, product: {}", sellerId, request.getProductName());
        Category category = new Category();
        category.setCategoryId(request.getCategoryId());

        Product product = Product.builder()
                // Note: Product entity has no sellerId field
                // You may need to add it or use a different approach
                .category(category) // TODO: Find or create Category entity
                .productName(request.getProductName())
                .description(request.getDescription())
                .condition(ProductCondition.valueOf(request.getCondition()))
                .createdAt(LocalDateTime.now())
                .build();

        product = productRepository.save(product);

        log.info("Product created: {}", product.getProductId());
        return ResponseEntity.status(HttpStatus.CREATED).body(product);
    }

    /**
     * Get all products
     * GET /api/products
     */
    @GetMapping
    public ResponseEntity<List<Product>> getAllProducts() {
        log.info("GET /api/products");

        List<Product> products = productRepository.findAll();
        return ResponseEntity.ok(products);
    }
}
