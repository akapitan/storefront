package com.storefront.inventory;

import java.util.Optional;
import java.util.UUID;

/**
 * InventoryApi — the ONLY public contract of the Inventory module.
 *
 * Other modules query inventory exclusively through this interface.
 * Internal classes (StockRepository, StockService, etc.) are package-private.
 */
public interface InventoryApi {

    Optional<StockLevel> getStockLevel(UUID skuId);

    boolean isInStock(UUID skuId);

    void reserve(UUID skuId, int quantity);

    void release(UUID skuId, int quantity);

    // ─── Projection ───────────────────────────────────────────────────────────

    record StockLevel(
            UUID   skuId,
            int    quantity,
            String warehouseLocation,
            boolean isLow
    ) {}

    // ─── Exceptions ───────────────────────────────────────────────────────────

    class InsufficientStockException extends RuntimeException {
        public InsufficientStockException(UUID skuId, int requested, int available) {
            super("Insufficient stock for SKU %s: requested %d, available %d"
                    .formatted(skuId, requested, available));
        }
    }
}
