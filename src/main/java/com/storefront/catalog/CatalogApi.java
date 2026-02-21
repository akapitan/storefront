package com.storefront.catalog;

import com.storefront.shared.Pagination;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * CatalogApi — the ONLY public contract of the Catalog module.
 *
 * Other modules (Inventory, Cart, future Order module, etc.) interact with
 * Catalog exclusively through this interface.
 */
public interface CatalogApi {

    // ─── Category navigation ───────────────────────────────────────────────────

    List<CategoryNode> findTopLevelCategories();

    List<CategoryNode> findChildCategories(int parentId);

    List<CategoryBreadcrumb> findBreadcrumb(String categoryPath);

    Optional<CategoryNode> findCategoryBySlug(String slug);

    List<CategoryNode> findCategoryDescendants(String categoryPath);

    List<CategorySection> findAllCategoriesGrouped();

    // ─── Product group browse ──────────────────────────────────────────────────

    Slice<ProductGroupSummary> browseByCategory(String categoryPath, SliceRequest request);

    Optional<ProductGroupDetail> findProductGroupBySlug(String slug);

    // ─── Search ────────────────────────────────────────────────────────────────

    Pagination<ProductGroupSummary> search(String query, PageRequest request);

    List<ProductGroupSummary> searchDropdown(String query, int limit);

    // ─── SKU queries ───────────────────────────────────────────────────────────

    List<SkuRow> findVariantTable(UUID groupId, List<UUID> matchingSkuIds);

    List<UUID> findMatchingSkuIds(UUID groupId, java.util.Map<Integer, List<Integer>> enumFilters,
                                  java.util.Map<Integer, NumericRange> rangeFilters);

    Optional<SkuRow> findSkuByPartNumber(String partNumber);

    // ─── Column config ─────────────────────────────────────────────────────────

    List<ColumnConfig> findColumnConfig(UUID groupId);

    // ─── Filter facets ─────────────────────────────────────────────────────────

    List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds);

    List<AttributeSummary> findFilterableAttributes(int categoryId);

    // ─── Cross-module checks ───────────────────────────────────────────────────

    boolean skuExistsAndActive(UUID skuId);

    Optional<SkuPriceInfo> findSkuPriceInfo(UUID skuId, int quantity);

    // ─── Projection records ────────────────────────────────────────────────────

    record CategoryNode(
            int id,
            String name,
            String slug,
            String path,
            int groupCount,
            boolean isLeaf,
            short sortOrder,
            short depth,
            Integer parentId
    ) {}

    record CategoryGroup(
            CategoryNode header,
            List<CategoryNode> items
    ) {}

    record CategorySection(
            CategoryNode topLevel,
            List<CategoryGroup> groups
    ) {}

    record CategoryBreadcrumb(
            int id,
            String name,
            String slug
    ) {}

    record ProductGroupSummary(
            UUID id,
            String name,
            String subtitle,
            String slug,
            String overviewImageUrl,
            int skuCount,
            BigDecimal minPriceUsd,
            boolean anyInStock
    ) {}

    record ProductGroupDetail(
            UUID id,
            String name,
            String subtitle,
            String slug,
            String description,
            String engineeringNote,
            String overviewImageUrl,
            String diagramImageUrl,
            int skuCount,
            BigDecimal minPriceUsd,
            boolean anyInStock,
            int categoryId,
            String categoryName,
            String categoryPath
    ) {}

    record SkuRow(
            UUID id,
            String partNumber,
            String specsJson,
            String sellUnit,
            int sellQty,
            boolean inStock,
            BigDecimal price1ea,
            String priceTiersJson
    ) {}

    record ColumnConfig(
            int sortOrder,
            String role,
            String header,
            int widthPx,
            String key,
            String unitLabel,
            String dataType,
            String filterWidget,
            int filterSortOrder,
            boolean isFilterable
    ) {}

    record FacetGroup(
            int attributeId,
            String key,
            String label,
            String filterWidget,
            String unitLabel,
            List<FacetOption> options
    ) {}

    record FacetOption(
            Integer optionId,
            String value,
            String displayValue,
            int skuCount
    ) {}

    record NumericRange(BigDecimal min, BigDecimal max) {}

    record SkuPriceInfo(
            UUID skuId,
            String partNumber,
            BigDecimal unitPrice,
            String sellUnit
    ) {}

    record AttributeSummary(int id, String key, String label, String dataType, String filterWidget) {}
}
