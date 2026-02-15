package com.storefront.inventory.infrastructure;

import com.storefront.inventory.InventoryApi.StockLevel;
import com.storefront.inventory.domain.model.StockRepository;
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
class JooqStockRepository implements StockRepository {

    private final DSLContext primaryDsl;
    private final DSLContext readOnlyDsl;

    JooqStockRepository(
            DSLContext primaryDsl,
            @Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.primaryDsl = primaryDsl;
        this.readOnlyDsl = readOnlyDsl;
    }

    // ─── Reads ────────────────────────────────────────────────────────────────

    @Override
    @Cacheable(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional(readOnly = true)
    public Optional<StockLevel> findBySkuId(UUID skuId) {
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

    @Override
    @Transactional(readOnly = true)
    public boolean isInStock(UUID skuId) {
        return readOnlyDsl.fetchExists(
                INVENTORY,
                INVENTORY.SKU_ID.eq(skuId).and(INVENTORY.QUANTITY.gt(0)));
    }

    // ─── Writes ───────────────────────────────────────────────────────────────

    @Override
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    public void initialize(UUID skuId) {
        primaryDsl
                .insertInto(INVENTORY)
                .set(INVENTORY.SKU_ID, skuId)
                .set(INVENTORY.QUANTITY, 0)
                .set(INVENTORY.REORDER_POINT, 10)
                .onConflict(INVENTORY.SKU_ID)
                .doNothing()
                .execute();
    }

    @Override
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    public int decrementQuantity(UUID skuId, int amount) {
        var record = primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, INVENTORY.QUANTITY.minus(amount))
                .where(INVENTORY.SKU_ID.eq(skuId))
                .and(INVENTORY.QUANTITY.ge(amount))
                .returning(INVENTORY.QUANTITY)
                .fetchOne();

        return record == null ? -1 : record.getQuantity();
    }

    @Override
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    public int incrementQuantity(UUID skuId, int amount) {
        var record = primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, INVENTORY.QUANTITY.plus(amount))
                .where(INVENTORY.SKU_ID.eq(skuId))
                .returning(INVENTORY.QUANTITY)
                .fetchOne();

        return record == null ? 0 : record.getQuantity();
    }

    @Override
    @CacheEvict(value = "inventory", cacheManager = "redisCacheManager", key = "#skuId")
    @Transactional
    public void archive(UUID skuId) {
        primaryDsl
                .update(INVENTORY)
                .set(INVENTORY.QUANTITY, 0)
                .where(INVENTORY.SKU_ID.eq(skuId))
                .execute();
    }
}
