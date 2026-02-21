package com.storefront.catalog;

import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;

import java.util.List;

public interface SearchApi {

    Pagination<ProductApi.ProductGroupSummary> search(String query, PageRequest request);

    List<ProductApi.ProductGroupSummary> searchDropdown(String query, int limit);
}