package com.storefront.inventory;

import java.util.Optional;
import java.util.UUID;

/**
 * InventoryApi — the ONLY public contract of the Inventory module.
 * ══════════════════════════════════════════════════════════════════
 *
 * Other modules query inventory exclusively through this interface.
 * Internal classes (StockRepository, StockService, etc.) are package-private.
 */
public interface InventoryApi {

    /**
     * Get the current stock level for a product.
     * Returns empty if no stock record exists for this product.
     */
    Optional<StockLevel> getStockLevel(UUID productId);

    /**
     * Check whether a product is in stock (quantity > 0).
     */
    boolean isInStock(UUID productId);

    /**
     * Reserve stock for an order line item.
     * Decrements available quantity atomically.
     *
     * @throws InsufficientStockException if requested quantity exceeds available
     */
    void reserve(UUID productId, int quantity);

    /**
     * Release previously reserved stock (e.g. on order cancellation).
     */
    void release(UUID productId, int quantity);

    // ─── Projection ───────────────────────────────────────────────────────────

    record StockLevel(
            UUID   productId,
            int    quantity,
            String warehouseLocation,
            boolean isLow           // quantity <= reorderPoint
    ) {}

    // ─── Exceptions ───────────────────────────────────────────────────────────

    class InsufficientStockException extends RuntimeException {
        public InsufficientStockException(UUID productId, int requested, int available) {
            super("Insufficient stock for product %s: requested %d, available %d"
                    .formatted(productId, requested, available));
        }
    }
}
