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

    @Cacheable(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional(readOnly = true)
    Optional<StockLevel> findBySkuId(UUID skuId) {
        return readOnlyDsl
                .selectFrom(INVENTORY)
                .where(INVENTORY.SKU_ID.eq(skuId))
                .fetchOptional(r -> new StockLevel(
                        r.getSkuId(),
                        r.getQuantity(),
                        r.getWarehouseLocation(),
                        r.getQuantity() <= r.getReorderPoint()
                ));
    }

    @Transactional(readOnly = true)
    boolean isInStock(UUID skuId) {
        return readOnlyDsl.fetchExists(
                INVENTORY,
                INVENTORY.SKU_ID.eq(skuId).and(INVENTORY.QUANTITY.gt(0)));
    }

    // ─── Writes ───────────────────────────────────────────────────────────────

    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    void initialize(UUID skuId) {
        primaryDsl
                .insertInto(INVENTORY)
                .set(INVENTORY.SKU_ID, skuId)
                .set(INVENTORY.QUANTITY, 0)
                .set(INVENTORY.REORDER_POINT, 10)
                .onConflict(INVENTORY.SKU_ID)
                .doNothing()
                .execute();
    }

    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    int decrementQuantity(UUID skuId, int amount) {
        int updated = primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, INVENTORY.QUANTITY.minus(amount))
                .where(INVENTORY.SKU_ID.eq(skuId))
                .and(INVENTORY.QUANTITY.ge(amount))
                .execute();

        if (updated == 0) return -1;

        return primaryDsl
                .select(INVENTORY.QUANTITY)
                .from(INVENTORY)
                .where(INVENTORY.SKU_ID.eq(skuId))
                .fetchOne(INVENTORY.QUANTITY);
    }

    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    int incrementQuantity(UUID skuId, int amount) {
        primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, INVENTORY.QUANTITY.plus(amount))
                .where(INVENTORY.SKU_ID.eq(skuId))
                .execute();

        return primaryDsl
                .select(INVENTORY.QUANTITY)
                .from(INVENTORY)
                .where(INVENTORY.SKU_ID.eq(skuId))
                .fetchOne(INVENTORY.QUANTITY);
    }

    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    void archive(UUID skuId) {
        primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, 0)
                .where(INVENTORY.SKU_ID.eq(skuId))
                .execute();
    }
}
