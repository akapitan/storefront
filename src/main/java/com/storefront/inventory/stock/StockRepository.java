package com.storefront.inventory.stock;

import com.storefront.inventory.InventoryApi.StockLevel;
import org.jooq.DSLContext;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

import static com.storefront.jooq.tables.Inventory.INVENTORY;


/**
 * StockRepository — all inventory SQL via jOOQ.
 * Package-private: only StockService may use this directly.
 */
@Repository
class StockRepository {

    private final DSLContext primaryDsl;
    private final DSLContext readOnlyDsl;

    StockRepository(
            DSLContext primaryDsl,
            @Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.primaryDsl = primaryDsl;
        this.readOnlyDsl = readOnlyDsl;
    }

    // ─── Reads ────────────────────────────────────────────────────────────────

    @Cacheable(value = "inventory", cacheManager = "redisCacheManager", key = "#productId")
    @Transactional(readOnly = true)
    Optional<StockLevel> findByProductId(UUID productId) {
        return readOnlyDsl
                .selectFrom(INVENTORY)
                .where(INVENTORY.PRODUCT_ID.eq(productId))
                .fetchOptional(r -> new StockLevel(
                        r.getProductId(),
                        r.getQuantity(),
                        r.getWarehouseLocation(),
                        r.getQuantity() <= r.getReorderPoint()
                ));
    }

    @Transactional(readOnly = true)
    boolean isInStock(UUID productId) {
        return readOnlyDsl.fetchExists(
                INVENTORY,
                INVENTORY.PRODUCT_ID.eq(productId).and(INVENTORY.QUANTITY.gt(0)));
    }

    // ─── Writes ───────────────────────────────────────────────────────────────

    /**
     * Initialise a stock record for a newly created product.
     * Called by StockService when it receives a ProductCreated event.
     */
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#productId")
    @Transactional
    void initialize(UUID productId) {
        primaryDsl
                .insertInto(INVENTORY)
                .set(INVENTORY.PRODUCT_ID, productId)
                .set(INVENTORY.QUANTITY, 0)
                .set(INVENTORY.REORDER_POINT, 10)
                .onConflict(INVENTORY.PRODUCT_ID)
                .doNothing()   // idempotent — safe to call multiple times
                .execute();
    }

    /**
     * Atomically decrement stock quantity.
     * Uses a conditional UPDATE with a check constraint to prevent negatives.
     * Returns the new quantity, or -1 if insufficient stock.
     */
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#productId")
    @Transactional
    int decrementQuantity(UUID productId, int amount) {
        int updated = primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, INVENTORY.QUANTITY.minus(amount))
                .where(INVENTORY.PRODUCT_ID.eq(productId))
                .and(INVENTORY.QUANTITY.ge(amount))  // prevent going below 0
                .execute();

        if (updated == 0) return -1; // insufficient stock

        return primaryDsl
                .select(INVENTORY.QUANTITY)
                .from(INVENTORY)
                .where(INVENTORY.PRODUCT_ID.eq(productId))
                .fetchOne(INVENTORY.QUANTITY);
    }

    /**
     * Atomically increment stock quantity (release reservation or replenishment).
     */
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#productId")
    @Transactional
    int incrementQuantity(UUID productId, int amount) {
        primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, INVENTORY.QUANTITY.plus(amount))
                .where(INVENTORY.PRODUCT_ID.eq(productId))
                .execute();

        return primaryDsl
                .select(INVENTORY.QUANTITY)
                .from(INVENTORY)
                .where(INVENTORY.PRODUCT_ID.eq(productId))
                .fetchOne(INVENTORY.QUANTITY);
    }

    /**
     * Soft-archive an inventory record (product deactivated).
     */
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#productId")
    @Transactional
    void archive(UUID productId) {
        primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, 0)
                .where(INVENTORY.PRODUCT_ID.eq(productId))
                .execute();
    }
}
