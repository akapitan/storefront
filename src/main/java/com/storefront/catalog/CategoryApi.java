package com.storefront.catalog;

import java.util.List;
import java.util.Optional;

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
}