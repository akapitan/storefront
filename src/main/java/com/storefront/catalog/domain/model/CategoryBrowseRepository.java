package com.storefront.catalog.domain.model;

import com.storefront.catalog.CategoryApi.FilteredCategory;
import com.storefront.catalog.ProductApi.FacetGroup;
import com.storefront.catalog.ProductApi.NumericRange;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface CategoryBrowseRepository {

    /**
     * Mid-level: direct children of parentId whose descendants have matching SKUs.
     * Counts = distinct matching SKUs under each child's subtree.
     */
    List<FilteredCategory> findFilteredChildren(
            int parentId,
            String parentPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);

    /**
     * Mid-level: union of all filterable attributes across descendant leaves,
     * restricted to SKUs matching current filters. Counts per option.
     */
    List<FacetGroup> findMidLevelFacets(
            String categoryPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);

    /**
     * Leaf: attributes defined at this category (not descendants).
     * Counts per option, restricted to currently matching SKUs.
     */
    List<FacetGroup> findLeafFacets(
            int categoryId,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);

    /**
     * Leaf: matching SKU IDs keyed by product_group_id.
     * Groups with zero matching SKUs are omitted entirely.
     */
    Map<UUID, List<UUID>> findMatchingSkuIdsByGroup(
            int categoryId,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters);
}