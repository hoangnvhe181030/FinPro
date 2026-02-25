package com.ex.auction.controller;

import com.ex.auction.domain.entity.Category;
import com.ex.auction.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class CategoryController {

    private final CategoryRepository categoryRepository;

    /**
     * Get all categories
     * GET /api/categories
     */
    @GetMapping
    public ResponseEntity<List<Category>> getAllCategories() {
        log.info("==> GET /api/categories - Fetching all categories");

        try {
            List<Category> categories = categoryRepository.findAll();
            log.info("<== GET /api/categories - SUCCESS: Found {} categories", categories.size());

            // Log each category for debugging
            categories.forEach(cat -> log.debug("Category: id={}, name={}, description={}",
                    cat.getCategoryId(), cat.getCategoryName(), cat.getDescription()));

            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            log.error("<== GET /api/categories - ERROR: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to fetch categories: " + e.getMessage(), e);
        }
    }

    /**
     * Get root categories (no parent)
     * GET /api/categories/root
     */
    @GetMapping("/root")
    public ResponseEntity<List<Category>> getRootCategories() {
        log.info("==> GET /api/categories/root - Fetching root categories");

        try {
            List<Category> categories = categoryRepository.findByParentCategoryIsNull();
            log.info("<== GET /api/categories/root - SUCCESS: Found {} root categories", categories.size());
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            log.error("<== GET /api/categories/root - ERROR: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to fetch root categories: " + e.getMessage(), e);
        }
    }

    /**
     * Get category by ID
     * GET /api/categories/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<Category> getCategoryById(@PathVariable Long id) {
        log.info("==> GET /api/categories/{} - Fetching category by ID", id);

        try {
            Category category = categoryRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Category not found: " + id));
            log.info("<== GET /api/categories/{} - SUCCESS: Found category '{}'", id, category.getCategoryName());
            return ResponseEntity.ok(category);
        } catch (Exception e) {
            log.error("<== GET /api/categories/{} - ERROR: {}", id, e.getMessage(), e);
            throw e;
        }
    }
}
