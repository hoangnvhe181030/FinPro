package com.ex.auction.dto;
import jakarta.validation.Valid;
// DTO
public class ProductCreateRequest {
    @jakarta.validation.constraints.NotBlank
    private String productName;

    @jakarta.validation.constraints.NotBlank
    private String description;

    // Category name as string (we'll create/find the entity later)
    private Long categoryId;

    @jakarta.validation.constraints.NotBlank
    private String condition;

    // Getters and setters
    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCondition() {
        return condition;
    }

    public void setCondition(String condition) {
        this.condition = condition;
    }
}
