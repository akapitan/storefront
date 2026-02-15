package com.storefront.catalog.domain.model;

import com.storefront.catalog.CatalogApi.CategoryBreadcrumb;
import com.storefront.catalog.CatalogApi.CategoryNode;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository {

    List<CategoryNode> findTopLevel();

    List<CategoryNode> findChildren(int parentId);

    List<CategoryBreadcrumb> findBreadcrumb(String categoryPath);

    Optional<CategoryNode> findBySlug(String slug);

    List<CategoryNode> findDescendants(String ancestorPath);
}
