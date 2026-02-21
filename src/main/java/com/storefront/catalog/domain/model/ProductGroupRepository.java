package com.storefront.catalog.domain.model;

import com.storefront.catalog.ProductApi.ProductGroupDetail;
import com.storefront.catalog.ProductApi.ProductGroupSummary;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductGroupRepository {

    Slice<ProductGroupSummary> browseByCategory(String categoryPath, SliceRequest request);

    Optional<ProductGroupDetail> findBySlug(String slug);

    Pagination<ProductGroupSummary> search(String query, PageRequest request);

    List<ProductGroupSummary> searchDropdown(String query, int limit);

    List<ProductGroupSummary> findSummariesByIds(Collection<UUID> ids);
}
