package com.storefront.catalog.application;

import com.storefront.catalog.CategoryApi;
import com.storefront.catalog.ProductApi.FacetGroup;
import com.storefront.catalog.ProductApi.NumericRange;
import com.storefront.catalog.domain.model.AttributeRepository;
import com.storefront.catalog.domain.model.CategoryBrowseRepository;
import com.storefront.catalog.domain.model.CategoryRepository;
import com.storefront.catalog.domain.model.ProductGroupRepository;
import com.storefront.catalog.domain.model.SkuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
class CategoryService implements CategoryApi {

    private final CategoryRepository categoryRepository;
    private final CategoryBrowseRepository categoryBrowseRepository;
    private final ProductGroupRepository productGroupRepository;
    private final SkuRepository skuRepository;
    private final AttributeRepository attributeRepository;

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

    // ─── Faceted browse methods ──────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<FilteredCategory> findFilteredChildren(
            int parentId, String parentPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {
        return categoryBrowseRepository.findFilteredChildren(parentId, parentPath, enumFilters, rangeFilters);
    }

    @Override
    @Transactional(readOnly = true)
    public List<FacetGroup> findMidLevelFacets(
            String categoryPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {
        return categoryBrowseRepository.findMidLevelFacets(categoryPath, enumFilters, rangeFilters);
    }

    @Override
    @Transactional(readOnly = true)
    public List<FacetGroup> findLeafFacets(
            int categoryId,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {
        return categoryBrowseRepository.findLeafFacets(categoryId, enumFilters, rangeFilters);
    }

    @Override
    @Transactional(readOnly = true)
    public List<LeafGroupTable> findLeafGroupTables(
            int categoryId, String categoryPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {

        var skuIdsByGroup = categoryBrowseRepository.findMatchingSkuIdsByGroup(
                categoryId, enumFilters, rangeFilters);

        if (skuIdsByGroup.isEmpty()) return List.of();

        var groups = productGroupRepository.findSummariesByIds(skuIdsByGroup.keySet());

        List<LeafGroupTable> result = new ArrayList<>();
        for (var group : groups) {
            var skuIds = skuIdsByGroup.get(group.id());
            var rows = skuRepository.findVariantTable(group.id(), skuIds);
            var columns = attributeRepository.findColumnConfig(group.id());
            result.add(new LeafGroupTable(
                    group.id(), group.name(), group.slug(),
                    group.overviewImageUrl(), group.minPriceUsd(),
                    columns, rows));
        }
        return result;
    }
}