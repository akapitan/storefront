package com.storefront.catalog;

import com.storefront.shared.Pagination;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;

import java.util.Optional;
import java.util.UUID;

/**
 * CatalogApi — the ONLY public contract of the Catalog module.
 * ═════════════════════════════════════════════════════════════
 *
 * Other modules (Inventory, future Order module, etc.) interact with
 * Catalog exclusively through this interface. They must NEVER import
 * from com.storefront.catalog.product.* or com.storefront.catalog.category.*
 *
 * Spring Modulith enforces this: accessing internal packages from outside
 * the module will fail the @ApplicationModuleTest boundary verification.
 *
 * Implementation: CatalogService (package-private to catalog module).
 */
public interface CatalogApi {

    /**
     * Find a product by its SKU.
     * Returns empty if the product does not exist or is inactive.
     */
    Optional<ProductDetail> findBySku(String sku);

    /**
     * Find a product by its internal ID.
     * Returns empty if the product does not exist or is inactive.
     */
    Optional<ProductDetail> findById(UUID productId);

    /**
     * Browse active products in a category.
     * Uses {@link Slice} — no COUNT(*) — suitable for infinite scroll.
     */
    Slice<ProductSummary> browseByCategory(UUID categoryId, SliceRequest request);

    /**
     * Search products by keyword.
     * Uses {@link Pagination} — returns total count for result headers.
     */
    Pagination<ProductSummary> search(String query, PageRequest request);

    /**
     * Check whether a product exists and is active.
     * Used by Inventory before initialising a stock record.
     */
    boolean existsAndActive(UUID productId);

    // ─── Projection records (public — used by callers of CatalogApi) ──────────

    record ProductSummary(
            UUID   id,
            String sku,
            String name,
            java.math.BigDecimal price,
            String thumbnailKey,
            String categoryName
    ) {}

    record ProductDetail(
            UUID   id,
            String sku,
            String name,
            String description,
            java.math.BigDecimal price,
            String categoryName,
            UUID   categoryId,
            com.fasterxml.jackson.databind.JsonNode attributes,
            java.util.List<String> imageKeys
    ) {}
}
