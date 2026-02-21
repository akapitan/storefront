package com.storefront.catalog.application;

import com.storefront.catalog.ProductApi;
import com.storefront.catalog.domain.model.AttributeRepository;
import com.storefront.catalog.domain.model.ProductGroupRepository;
import com.storefront.catalog.domain.model.SkuRepository;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
class ProductGroupService implements ProductApi {

    private final ProductGroupRepository productGroupRepository;
    private final SkuRepository skuRepository;
    private final AttributeRepository attributeRepository;

    @Override
    @Transactional(readOnly = true)
    public Slice<ProductGroupSummary> browseByCategory(String categoryPath, SliceRequest request) {
        return productGroupRepository.browseByCategory(categoryPath, request);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<ProductGroupDetail> findProductGroupBySlug(String slug) {
        return productGroupRepository.findBySlug(slug);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SkuRow> findVariantTable(UUID groupId, List<UUID> matchingSkuIds) {
        return skuRepository.findVariantTable(groupId, matchingSkuIds);
    }

    @Override
    @Transactional(readOnly = true)
    public List<UUID> findMatchingSkuIds(UUID groupId,
                                          Map<Integer, List<Integer>> enumFilters,
                                          Map<Integer, NumericRange> rangeFilters) {
        return skuRepository.findMatchingSkuIds(groupId, enumFilters, rangeFilters);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<SkuRow> findSkuByPartNumber(String partNumber) {
        return skuRepository.findByPartNumber(partNumber);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ColumnConfig> findColumnConfig(UUID groupId) {
        return attributeRepository.findColumnConfig(groupId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds) {
        return attributeRepository.findFacetCounts(groupId, matchingSkuIds);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AttributeSummary> findFilterableAttributes(int categoryId) {
        return attributeRepository.findFilterableAttributes(categoryId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean skuExistsAndActive(UUID skuId) {
        return skuRepository.existsAndActive(skuId);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<SkuPriceInfo> findSkuPriceInfo(UUID skuId, int quantity) {
        return skuRepository.findPriceInfo(skuId, quantity);
    }
}
