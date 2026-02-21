package com.storefront.catalog.application;

import com.storefront.catalog.ProductApi;
import com.storefront.catalog.SearchApi;
import com.storefront.catalog.domain.model.ProductGroupRepository;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
class SearchService implements SearchApi {

    private final ProductGroupRepository productGroupRepository;

    @Override
    @Transactional(readOnly = true)
    public Pagination<ProductApi.ProductGroupSummary> search(String query, PageRequest request) {
        return productGroupRepository.search(query, request);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductApi.ProductGroupSummary> searchDropdown(String query, int limit) {
        return productGroupRepository.searchDropdown(query, limit);
    }
}
