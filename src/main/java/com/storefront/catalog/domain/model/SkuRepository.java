package com.storefront.catalog.domain.model;

import com.storefront.catalog.CatalogApi.NumericRange;
import com.storefront.catalog.CatalogApi.SkuPriceInfo;
import com.storefront.catalog.CatalogApi.SkuRow;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface SkuRepository {

    List<SkuRow> findVariantTable(UUID groupId, List<UUID> matchingSkuIds);

    List<UUID> findMatchingSkuIds(UUID groupId, Map<Integer, List<Integer>> enumFilters,
                                  Map<Integer, NumericRange> rangeFilters);

    Optional<SkuRow> findByPartNumber(String partNumber);

    boolean existsAndActive(UUID skuId);

    Optional<SkuPriceInfo> findPriceInfo(UUID skuId, int quantity);
}
