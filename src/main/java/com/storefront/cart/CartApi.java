package com.storefront.cart;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * CartApi — the ONLY public contract of the Cart module.
 * ═══════════════════════════════════════════════════════════
 *
 * Other modules (Order, future Promotion, etc.) interact with
 * Cart exclusively through this interface. They must NEVER import
 * from com.storefront.cart.* internal packages.
 *
 * Implementation: CartService (package-private to cart module).
 */
public interface CartApi {

    // ─── Cart lifecycle ───────────────────────────────────────────────────────

    /**
     * Get or create a cart for the current HTTP session.
     * Returns existing cart if one exists, creates new otherwise.
     *
     * @param sessionId HTTP session identifier
     * @return existing or newly created cart
     */
    Cart getOrCreateCart(String sessionId);

    /**
     * Get cart by ID. Used by Order module when converting cart to order.
     * Returns empty if cart doesn't exist.
     */
    Optional<Cart> findById(UUID cartId);

    /**
     * Get cart by session ID.
     */
    Optional<Cart> findBySessionId(String sessionId);

    // ─── Item management ──────────────────────────────────────────────────────

    /**
     * Add item to cart or increase quantity if already present.
     * Validates:
     *   - Product exists and is active (via CatalogApi)
     *   - Product is in stock (via InventoryApi)
     *   - Quantity doesn't exceed maximum (999)
     *
     * @param cartId cart identifier
     * @param productId product to add
     * @param quantity amount to add (positive integer)
     * @throws ProductNotAvailableException if product inactive or doesn't exist
     * @throws OutOfStockException if product has zero stock
     * @throws QuantityExceededException if resulting quantity > 999
     */
    void addItem(UUID cartId, UUID productId, int quantity);

    /**
     * Update item quantity. Setting to 0 removes the item.
     *
     * @param cartId cart identifier
     * @param itemId item to update
     * @param quantity new quantity (0 to remove)
     * @throws CartItemNotFoundException if item doesn't exist
     */
    void updateQuantity(UUID cartId, UUID itemId, int quantity);

    /**
     * Remove specific item from cart.
     *
     * @param cartId cart identifier
     * @param itemId item to remove
     */
    void removeItem(UUID cartId, UUID itemId);

    /**
     * Remove all items. Called after order placement.
     *
     * @param cartId cart to clear
     */
    void clearCart(UUID cartId);

    // ─── Queries ──────────────────────────────────────────────────────────────

    /**
     * Get cart summary with totals and line items.
     */
    CartSummary getSummary(UUID cartId);

    /**
     * Count total items in cart (sum of quantities).
     * Used for cart icon badge in UI.
     */
    int getItemCount(UUID cartId);

    /**
     * Check if cart is empty.
     */
    boolean isEmpty(UUID cartId);

    // ─── Projection records (public — used by callers of CartApi) ────────────

    record Cart(
            UUID    id,
            UUID    customerId,         // NULL for anonymous
            String  sessionId,
            Instant createdAt,
            Instant updatedAt,
            List<CartItemDto> items
    ) {}

    record CartItemDto(
            UUID       id,
            UUID       productId,
            String     productName,
            String     productSku,
            String     thumbnailKey,
            int        quantity,
            BigDecimal unitPrice,
            BigDecimal lineTotal        // quantity × unitPrice
    ) {}

    record CartSummary(
            UUID       cartId,
            int        itemCount,       // number of distinct products
            int        totalQuantity,   // sum of all quantities
            BigDecimal subtotal         // sum of all line totals
    ) {}

    // ─── Exceptions ───────────────────────────────────────────────────────────

    class ProductNotAvailableException extends RuntimeException {
        public ProductNotAvailableException(UUID productId) {
            super("Product not available: " + productId);
        }
    }

    class OutOfStockException extends RuntimeException {
        public OutOfStockException(UUID productId) {
            super("Product out of stock: " + productId);
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

