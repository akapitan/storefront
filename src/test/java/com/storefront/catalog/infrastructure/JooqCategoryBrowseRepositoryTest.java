package com.storefront.catalog.infrastructure;

import com.storefront.catalog.BaseIntegrationTest;
import com.storefront.catalog.domain.model.CategoryBrowseRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class JooqCategoryBrowseRepositoryTest extends BaseIntegrationTest {

    @Autowired
    CategoryBrowseRepository repo;

    @Test
    void findFilteredChildrenReturnsListWithNoFilters() {
        var result = repo.findFilteredChildren(999, "NonExistent", Map.of(), Map.of());
        assertThat(result).isNotNull().isEmpty();
    }

    @Test
    void findMidLevelFacetsReturnsListForNonExistentPath() {
        var result = repo.findMidLevelFacets("NonExistent.Path", Map.of(), Map.of());
        assertThat(result).isNotNull().isEmpty();
    }

    @Test
    void findLeafFacetsReturnsListForNonExistentCategory() {
        var result = repo.findLeafFacets(9999, Map.of(), Map.of());
        assertThat(result).isNotNull().isEmpty();
    }

    @Test
    void findMatchingSkuIdsByGroupReturnsEmptyForNonExistentCategory() {
        var result = repo.findMatchingSkuIdsByGroup(9999, Map.of(), Map.of());
        assertThat(result).isNotNull().isEmpty();
    }
}