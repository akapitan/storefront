package com.storefront.catalog;

import com.storefront.catalog.ProductApi.ColumnConfig;
import com.storefront.catalog.ProductApi.FacetGroup;
import com.storefront.catalog.ProductApi.NumericRange;
import com.storefront.catalog.ProductApi.SkuRow;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface CategoryApi {

    List<CategoryNode> findTopLevelCategories();

    List<CategoryNode> findChildCategories(int parentId);

    List<CategoryBreadcrumb> findBreadcrumb(String categoryPath);

    Optional<CategoryNode> findCategoryBySlug(String slug);

    List<CategoryNode> findCategoryDescendants(String categoryPath);

    List<CategorySection> findAllCategoriesGrouped();

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

    // ─── Faceted browse records ──────────────────────────────────────────────

    record FilteredCategory(
            int id,
            String name,
            String slug,
            String path,
            boolean isLeaf,
            short depth,
            short sortOrder,
            long skuCount
    ) {}

    record LeafGroupTable(
            UUID groupId,
            String groupName,
            String groupSlug,
            String overviewImageUrl,
            BigDecimal minPriceUsd,
            List<ColumnConfig> columns,
            List<SkuRow> rows
    ) {}

    // ─── Faceted browse methods ──────────────────────────────────────────────

    List<FilteredCategory> findFilteredChildren(
            int parentId, String parentPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);

    List<FacetGroup> findMidLevelFacets(
            String categoryPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);

    List<FacetGroup> findLeafFacets(
            int categoryId,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);

    List<LeafGroupTable> findLeafGroupTables(
            int categoryId, String categoryPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);
}