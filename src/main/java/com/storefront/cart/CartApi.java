package com.storefront.cart;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * CartApi — the ONLY public contract of the Cart module.
 *
 * Other modules (Order, future Promotion, etc.) interact with
 * Cart exclusively through this interface.
 */
public interface CartApi {

    // ─── Cart lifecycle ───────────────────────────────────────────────────────

    Cart getOrCreateCart(String sessionId);

    Optional<Cart> findById(UUID cartId);

    Optional<Cart> findBySessionId(String sessionId);

    // ─── Item management ──────────────────────────────────────────────────────

    /**
     * Add item to cart or increase quantity if already present.
     * Validates:
     *   - SKU exists and is active (via ProductApi)
     *   - SKU is in stock (via InventoryApi)
     *   - Quantity doesn't exceed maximum (999)
     */
    void addItem(UUID cartId, UUID skuId, int quantity);

    void updateQuantity(UUID cartId, UUID itemId, int quantity);

    void removeItem(UUID cartId, UUID itemId);

    void clearCart(UUID cartId);

    // ─── Queries ──────────────────────────────────────────────────────────────

    CartSummary getSummary(UUID cartId);

    int getItemCount(UUID cartId);

    boolean isEmpty(UUID cartId);

    // ─── Projection records ───────────────────────────────────────────────────

    record Cart(
            UUID    id,
            UUID    customerId,
            String  sessionId,
            Instant createdAt,
            Instant updatedAt,
            List<CartItemDto> items
    ) {}

    record CartItemDto(
            UUID       id,
            UUID       skuId,
            String     skuName,
            String     partNumber,
            String     thumbnailKey,
            int        quantity,
            BigDecimal unitPrice,
            BigDecimal lineTotal
    ) {}

    record CartSummary(
            UUID       cartId,
            int        itemCount,
            int        totalQuantity,
            BigDecimal subtotal
    ) {}

    // ─── Exceptions ───────────────────────────────────────────────────────────

    class SkuNotAvailableException extends RuntimeException {
        public SkuNotAvailableException(UUID skuId) {
            super("SKU not available: " + skuId);
        }
    }

    class OutOfStockException extends RuntimeException {
        public OutOfStockException(UUID skuId) {
            super("SKU out of stock: " + skuId);
        }
    }

    class CartNotFoundException extends RuntimeException {
        public CartNotFoundException(UUID cartId) {
            super("Cart not found: " + cartId);
        }
    }

    class CartItemNotFoundException extends RuntimeException {
        public CartItemNotFoundException(UUID itemId) {
            super("Cart item not found: " + itemId);
        }
    }

    class QuantityExceededException extends RuntimeException {
        public QuantityExceededException(int requested, int max) {
            super("Quantity %d exceeds maximum allowed %d".formatted(requested, max));
        }
    }
}
