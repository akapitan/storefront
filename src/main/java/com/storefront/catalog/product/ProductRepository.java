package com.storefront.catalog.product;

import com.fasterxml.jackson.databind.JsonNode;
import com.storefront.catalog.CatalogApi.ProductDetail;
import com.storefront.catalog.CatalogApi.ProductSummary;
import com.storefront.jooq.tables.records.ProductRecord;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;
import com.storefront.shared.jooq.JsonNodeConverter;
import org.jooq.DSLContext;
import org.jooq.Field;
import org.jooq.JSONB;
import org.jooq.Record;
import org.jooq.impl.DSL;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static com.storefront.jooq.Tables.CATEGORY;
import static com.storefront.jooq.Tables.PRODUCT;

/**
 * ProductRepository — all product SQL via jOOQ.
 * <p>
 * Read queries  → readOnlyDsl  (RDS Read Replica)
 * Write queries → primaryDsl   (RDS Primary)
 * <p>
 * Package-private: only ProductService (same package) may use this.
 * External modules go through CatalogApi → CatalogService.
 */
@Repository
class ProductRepository {

    private final DSLContext primaryDsl;
    private final DSLContext readOnlyDsl;

    private static final JsonNodeConverter JSON_NODE_CONVERTER = new JsonNodeConverter();

    ProductRepository(
            DSLContext primaryDsl,
            @Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.primaryDsl = primaryDsl;
        this.readOnlyDsl = readOnlyDsl;
    }

    // ─── Single product ───────────────────────────────────────────────────────

    @Cacheable(value = "product-detail", cacheManager = "redisCacheManager", key = "#sku")
    @Transactional(readOnly = true)
    Optional<ProductDetail> findBySku(String sku) {
        return readOnlyDsl
                .select(
                        PRODUCT.ID, PRODUCT.SKU, PRODUCT.NAME, PRODUCT.DESCRIPTION,
                        PRODUCT.PRICE, PRODUCT.ATTRIBUTES, PRODUCT.IMAGE_KEYS,
                        CATEGORY.NAME.as("categoryName"), CATEGORY.ID.as("categoryId")
                )
                .from(PRODUCT)
                .join(CATEGORY).on(CATEGORY.ID.eq(PRODUCT.CATEGORY_ID))
                .where(PRODUCT.SKU.eq(sku).and(PRODUCT.ACTIVE.isTrue()))
                .fetchOptional(this::toDetail);
    }

    @Cacheable(value = "product-detail", cacheManager = "redisCacheManager", key = "#productId")
    @Transactional(readOnly = true)
    Optional<ProductDetail> findById(UUID productId) {
        return readOnlyDsl
                .select(
                        PRODUCT.ID, PRODUCT.SKU, PRODUCT.NAME, PRODUCT.DESCRIPTION,
                        PRODUCT.PRICE, PRODUCT.ATTRIBUTES, PRODUCT.IMAGE_KEYS,
                        CATEGORY.NAME.as("categoryName"), CATEGORY.ID.as("categoryId")
                )
                .from(PRODUCT)
                .join(CATEGORY).on(CATEGORY.ID.eq(PRODUCT.CATEGORY_ID))
                .where(PRODUCT.ID.eq(productId).and(PRODUCT.ACTIVE.isTrue()))
                .fetchOptional(this::toDetail);
    }

    @Transactional(readOnly = true)
    boolean existsAndActive(UUID productId) {
        return readOnlyDsl.fetchExists(
                PRODUCT, PRODUCT.ID.eq(productId).and(PRODUCT.ACTIVE.isTrue()));
    }

    // ─── Browse (Slice — no COUNT) ────────────────────────────────────────────

    @Cacheable(
            value = "product-listing", cacheManager = "redisCacheManager",
            key = "#categoryId + ':' + #request.page() + ':' + #request.pageSize() + ':' + #request.sort()"
    )
    @Transactional(readOnly = true)
    Slice<ProductSummary> browseByCategory(UUID categoryId, SliceRequest request) {
        var orderBy = sortField(request.sort());

        List<ProductSummary> rows = readOnlyDsl
                .select(
                        PRODUCT.ID, PRODUCT.SKU, PRODUCT.NAME,
                        PRODUCT.PRICE, PRODUCT.THUMBNAIL_KEY,
                        CATEGORY.NAME.as("categoryName")
                )
                .from(PRODUCT)
                .join(CATEGORY).on(CATEGORY.ID.eq(PRODUCT.CATEGORY_ID))
                .where(PRODUCT.CATEGORY_ID.eq(categoryId).and(PRODUCT.ACTIVE.isTrue()))
                .orderBy(orderBy)
                .limit(request.fetchSize())   // pageSize + 1 — Slice detects hasMore
                .offset(request.offset())
                .fetch(this::toSummary);

        return Slice.of(rows, request);
    }

    // ─── Search (Pagination — with COUNT) ────────────────────────────────────

    @Cacheable(
            value = "search-results", cacheManager = "redisCacheManager",
            key = "#query + ':' + #request.page() + ':' + #request.pageSize()"
    )
    @Transactional(readOnly = true)
    Pagination<ProductSummary> search(String query, PageRequest request) {
        var tsQuery = DSL.field("plainto_tsquery('english', {0})", Boolean.class, query);
        var tsVector = DSL.field("search_vector", Boolean.class);
        var rank = DSL.field("ts_rank(search_vector, plainto_tsquery('english', {0}))", Double.class, query);
        var condition = DSL.condition("{0} @@ {1}", tsVector, tsQuery)
                .and(PRODUCT.ACTIVE.isTrue());

        int total = readOnlyDsl.selectCount().from(PRODUCT)
                .where(condition).fetchOne(0, int.class);

        List<ProductSummary> items = readOnlyDsl
                .select(
                        PRODUCT.ID, PRODUCT.SKU, PRODUCT.NAME,
                        PRODUCT.PRICE, PRODUCT.THUMBNAIL_KEY,
                        CATEGORY.NAME.as("categoryName")
                )
                .from(PRODUCT)
                .join(CATEGORY).on(CATEGORY.ID.eq(PRODUCT.CATEGORY_ID))
                .where(condition)
                .orderBy(rank.desc())
                .limit(request.pageSize())
                .offset(request.offset())
                .fetch(this::toSummary);

        return Pagination.of(items, total, request);
    }

    // ─── Writes ───────────────────────────────────────────────────────────────

    @Caching(evict = {
            @CacheEvict(value = "product-detail", cacheManager = "redisCacheManager", allEntries = true),
            @CacheEvict(value = "product-listing", cacheManager = "redisCacheManager", allEntries = true),
            @CacheEvict(value = "search-results", cacheManager = "redisCacheManager", allEntries = true),
    })
    @Transactional
    UUID save(ProductRecord product) {
        return primaryDsl
                .insertInto(PRODUCT)
                .set(product)
                .onConflict(PRODUCT.SKU)
                .doUpdate().set(product)
                .returningResult(PRODUCT.ID)
                .fetchOne(PRODUCT.ID);
    }

    @Caching(evict = {
            @CacheEvict(value = "product-detail", cacheManager = "redisCacheManager", allEntries = true),
            @CacheEvict(value = "product-listing", cacheManager = "redisCacheManager", allEntries = true),
            @CacheEvict(value = "search-results", cacheManager = "redisCacheManager", allEntries = true),
    })
    @Transactional
    void deactivate(UUID productId) {
        primaryDsl.update(PRODUCT)
                .set(PRODUCT.ACTIVE, false)
                .where(PRODUCT.ID.eq(productId))
                .execute();
    }

    // ─── Mappers ──────────────────────────────────────────────────────────────

    private ProductDetail toDetail(Record r) {
        String[] keys = r.get(PRODUCT.IMAGE_KEYS);
        JsonNode attributes = JSON_NODE_CONVERTER.from(r.get(PRODUCT.ATTRIBUTES));
        return new ProductDetail(
                r.get(PRODUCT.ID),
                r.get(PRODUCT.SKU),
                r.get(PRODUCT.NAME),
                r.get(PRODUCT.DESCRIPTION),
                r.get(PRODUCT.PRICE),
                r.get("categoryName", String.class),
                r.get("categoryId", UUID.class),
                attributes,
                keys == null ? List.of() : Arrays.asList(keys)
        );
    }

    private ProductSummary toSummary(Record r) {
        return new ProductSummary(
                r.get(PRODUCT.ID),
                r.get(PRODUCT.SKU),
                r.get(PRODUCT.NAME),
                r.get(PRODUCT.PRICE),
                r.get(PRODUCT.THUMBNAIL_KEY),
                r.get("categoryName", String.class)
        );
    }

    private org.jooq.SortField<?> sortField(String sort) {
        return switch (sort) {
            case "price_asc" -> PRODUCT.PRICE.asc();
            case "price_desc" -> PRODUCT.PRICE.desc();
            case "name" -> PRODUCT.NAME.asc();
            default -> PRODUCT.DISPLAY_ORDER.asc();
        };
    }
}
