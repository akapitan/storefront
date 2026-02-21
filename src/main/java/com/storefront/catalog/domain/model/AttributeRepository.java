package com.storefront.catalog.domain.model;

import com.storefront.catalog.CatalogApi.AttributeSummary;
import com.storefront.catalog.CatalogApi.ColumnConfig;
import com.storefront.catalog.CatalogApi.FacetGroup;

import java.util.List;
import java.util.UUID;

public interface AttributeRepository {

    List<ColumnConfig> findColumnConfig(UUID groupId);

    List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds);

    List<AttributeSummary> findFilterableAttributes(int categoryId);
}
