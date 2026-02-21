package com.storefront.catalog;

import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface ProductApi {

    // ─── Product group browse ──────────────────────────────────────────────────

    Slice<ProductGroupSummary> browseByCategory(String categoryPath, SliceRequest request);

    Optional<ProductGroupDetail> findProductGroupBySlug(String slug);

    // ─── SKU queries ───────────────────────────────────────────────────────────

    List<SkuRow> findVariantTable(UUID groupId, List<UUID> matchingSkuIds);

    List<UUID> findMatchingSkuIds(UUID groupId, Map<Integer, List<Integer>> enumFilters,
                                  Map<Integer, NumericRange> rangeFilters);

    Optional<SkuRow> findSkuByPartNumber(String partNumber);

    // ─── Column config ─────────────────────────────────────────────────────────

    List<ColumnConfig> findColumnConfig(UUID groupId);

    // ─── Filter facets ─────────────────────────────────────────────────────────

    List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds);

    List<AttributeSummary> findFilterableAttributes(int categoryId);

    // ─── Bulk lookups ─────────────────────────────────────────────────────

    List<ProductGroupSummary> findProductGroupSummariesByIds(Collection<UUID> ids);

    // ─── Cross-module checks ───────────────────────────────────────────────────

    boolean skuExistsAndActive(UUID skuId);

    Optional<SkuPriceInfo> findSkuPriceInfo(UUID skuId, int quantity);

    // ─── Projection records ────────────────────────────────────────────────────

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
            String imageUrl,
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