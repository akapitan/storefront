package com.storefront.catalog.product;

import java.math.BigDecimal;
import java.util.UUID;

/** Command to create a new product in the catalog. */
record CreateProductCommand(
        String     sku,
        String     name,
        String     description,
        UUID       categoryId,
        BigDecimal price,
        String     unitOfMeasure
) {
    CreateProductCommand {
        if (sku == null || sku.isBlank())   throw new IllegalArgumentException("SKU is required");
        if (name == null || name.isBlank()) throw new IllegalArgumentException("name is required");
        if (categoryId == null)             throw new IllegalArgumentException("categoryId is required");
        if (price == null || price.signum() < 0) throw new IllegalArgumentException("price must be >= 0");
        unitOfMeasure = (unitOfMeasure == null || unitOfMeasure.isBlank()) ? "each" : unitOfMeasure;
    }
}

/** Command to update an existing product. */
record UpdateProductCommand(
        UUID       productId,
        String     name,
        String     description,
        BigDecimal price
) {
    UpdateProductCommand {
        if (productId == null)              throw new IllegalArgumentException("productId is required");
        if (name == null || name.isBlank()) throw new IllegalArgumentException("name is required");
        if (price == null || price.signum() < 0) throw new IllegalArgumentException("price must be >= 0");
    }
}
