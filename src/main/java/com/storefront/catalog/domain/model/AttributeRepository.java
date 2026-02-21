package com.storefront.catalog.domain.model;

import com.storefront.catalog.ProductApi.AttributeSummary;
import com.storefront.catalog.ProductApi.ColumnConfig;
import com.storefront.catalog.ProductApi.FacetGroup;

import java.util.List;
import java.util.UUID;

public interface AttributeRepository {

    List<ColumnConfig> findColumnConfig(UUID groupId);

    List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds);

    List<AttributeSummary> findFilterableAttributes(int categoryId);
}
