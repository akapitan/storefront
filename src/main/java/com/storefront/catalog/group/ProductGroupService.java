package com.storefront.catalog.group;

import com.storefront.catalog.CatalogApi;
import com.storefront.catalog.domain.model.AttributeRepository;
import com.storefront.catalog.domain.model.CategoryRepository;
import com.storefront.catalog.domain.model.ProductGroupRepository;
import com.storefront.catalog.domain.model.SkuRepository;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
class ProductGroupService implements CatalogApi {

    private final CategoryRepository categoryRepository;
    private final ProductGroupRepository productGroupRepository;
    private final SkuRepository skuRepository;
    private final AttributeRepository attributeRepository;

    // ─── Category navigation ───────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<CategoryNode> findTopLevelCategories() {
        return categoryRepository.findTopLevel();
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategoryNode> findChildCategories(int parentId) {
        return categoryRepository.findChildren(parentId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategoryBreadcrumb> findBreadcrumb(String categoryPath) {
        return categoryRepository.findBreadcrumb(categoryPath);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<CategoryNode> findCategoryBySlug(String slug) {
        return categoryRepository.findBySlug(slug);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategoryNode> findCategoryDescendants(String categoryPath) {
        return categoryRepository.findDescendants(categoryPath);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategorySection> findAllCategoriesGrouped() {
        var all = categoryRepository.findAllWithinDepth((short) 2);

        var byDepth0 = all.stream().filter(n -> n.depth() == 0)
                .sorted(Comparator.comparingInt(CategoryNode::sortOrder))
                .toList();
        var byParent = all.stream().filter(n -> n.parentId() != null)
                .collect(Collectors.groupingBy(CategoryNode::parentId));

        List<CategorySection> sections = new ArrayList<>();
        for (var top : byDepth0) {
            var depth1Children = byParent.getOrDefault(top.id(), List.of());
            List<CategoryGroup> groups = new ArrayList<>();
            for (var header : depth1Children) {
                var leafItems = byParent.getOrDefault(header.id(), List.of());
                groups.add(new CategoryGroup(header, leafItems));
            }
            sections.add(new CategorySection(top, groups));
        }
        return sections;
    }

    // ─── Product group browse ──────────────────────────────────────────────────

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

    // ─── Search ────────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Pagination<ProductGroupSummary> search(String query, PageRequest request) {
        return productGroupRepository.search(query, request);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductGroupSummary> searchDropdown(String query, int limit) {
        return productGroupRepository.searchDropdown(query, limit);
    }

    // ─── SKU queries ───────────────────────────────────────────────────────────

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

    // ─── Column config ─────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<ColumnConfig> findColumnConfig(UUID groupId) {
        return attributeRepository.findColumnConfig(groupId);
    }

    // ─── Filter facets ─────────────────────────────────────────────────────────

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

    // ─── Cross-module checks ───────────────────────────────────────────────────

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
