# Catalog Module Reorganization — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the catalog module's God API (`CatalogApi`) into three focused sub-interfaces (`CategoryApi`, `ProductApi`, `SearchApi`), split the blob service and controller accordingly, and align packages to hexagonal convention.

**Architecture:** Vertical slices within one Spring Modulith module. Each sub-API gets its own service in `application/` and controller in `interfaces/`. Domain and infrastructure layers stay flat. `CatalogApi` is deleted — sub-APIs are the public contract.

**Tech Stack:** Java 21, Spring Boot 4.0.2, Spring Modulith, jOOQ, JTE, HTMX

---

### Task 0: Create directory structure

**Files:**
- Create: `src/main/java/com/storefront/catalog/application/` (package dir)
- Create: `src/main/java/com/storefront/catalog/interfaces/` (package dir)

**Step 1: Create the package directories**

```bash
mkdir -p src/main/java/com/storefront/catalog/application
mkdir -p src/main/java/com/storefront/catalog/interfaces
```

**Step 2: Commit**

```bash
git add -A && git commit -m "chore: create application/ and interfaces/ package dirs for catalog reorg"
```

---

### Task 1: Create CategoryApi interface

Extract category-related methods and records from `CatalogApi` into a new `CategoryApi` interface.

**Files:**
- Create: `src/main/java/com/storefront/catalog/CategoryApi.java`

**Step 1: Create CategoryApi.java**

```java
package com.storefront.catalog;

import java.util.List;
import java.util.Optional;

public interface CategoryApi {

    List<CategoryNode> findTopLevelCategories();

    List<CategoryNode> findChildCategories(int parentId);

    List<CategoryBreadcrumb> findBreadcrumb(String categoryPath);

    Optional<CategoryNode> findCategoryBySlug(String slug);

    List<CategoryNode> findCategoryDescendants(String categoryPath);

    List<CategorySection> findAllCategoriesGrouped();

    // ─── Projection records ────────────────────────────────────────────────────

    record CategoryNode(
            int id,
            String name,
            String slug,
            String path,
            int groupCount,
            boolean isLeaf,
            short sortOrder,
            short depth,
            Integer parentId
    ) {}

    record CategoryGroup(
            CategoryNode header,
            List<CategoryNode> items
    ) {}

    record CategorySection(
            CategoryNode topLevel,
            List<CategoryGroup> groups
    ) {}

    record CategoryBreadcrumb(
            int id,
            String name,
            String slug
    ) {}
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL (new interface, no dependents yet)

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/CategoryApi.java
git commit -m "feat: create CategoryApi interface with category methods and records"
```

---

### Task 2: Create ProductApi interface

Extract product, SKU, attribute, and cross-module methods and records from `CatalogApi` into `ProductApi`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/ProductApi.java`

**Step 1: Create ProductApi.java**

```java
package com.storefront.catalog;

import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface ProductApi {

    // ─── Product group browse ──────────────────────────────────────────────────

    Slice<ProductGroupSummary> browseByCategory(String categoryPath, SliceRequest request);

    Optional<ProductGroupDetail> findProductGroupBySlug(String slug);

    // ─── SKU queries ───────────────────────────────────────────────────────────

    List<SkuRow> findVariantTable(UUID groupId, List<UUID> matchingSkuIds);

    List<UUID> findMatchingSkuIds(UUID groupId, Map<Integer, List<Integer>> enumFilters,
                                  Map<Integer, NumericRange> rangeFilters);

    Optional<SkuRow> findSkuByPartNumber(String partNumber);

    // ─── Column config ─────────────────────────────────────────────────────────

    List<ColumnConfig> findColumnConfig(UUID groupId);

    // ─── Filter facets ─────────────────────────────────────────────────────────

    List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds);

    List<AttributeSummary> findFilterableAttributes(int categoryId);

    // ─── Cross-module checks ───────────────────────────────────────────────────

    boolean skuExistsAndActive(UUID skuId);

    Optional<SkuPriceInfo> findSkuPriceInfo(UUID skuId, int quantity);

    // ─── Projection records ────────────────────────────────────────────────────

    record ProductGroupSummary(
            UUID id,
            String name,
            String subtitle,
            String slug,
            String overviewImageUrl,
            int skuCount,
            BigDecimal minPriceUsd,
            boolean anyInStock
    ) {}

    record ProductGroupDetail(
            UUID id,
            String name,
            String subtitle,
            String slug,
            String description,
            String engineeringNote,
            String overviewImageUrl,
            String diagramImageUrl,
            int skuCount,
            BigDecimal minPriceUsd,
            boolean anyInStock,
            int categoryId,
            String categoryName,
            String categoryPath
    ) {}

    record SkuRow(
            UUID id,
            String partNumber,
            String specsJson,
            String sellUnit,
            int sellQty,
            boolean inStock,
            BigDecimal price1ea,
            String priceTiersJson
    ) {}

    record ColumnConfig(
            int sortOrder,
            String role,
            String header,
            int widthPx,
            String key,
            String unitLabel,
            String dataType,
            String filterWidget,
            int filterSortOrder,
            boolean isFilterable
    ) {}

    record FacetGroup(
            int attributeId,
            String key,
            String label,
            String filterWidget,
            String unitLabel,
            List<FacetOption> options
    ) {}

    record FacetOption(
            Integer optionId,
            String value,
            String displayValue,
            int skuCount
    ) {}

    record NumericRange(BigDecimal min, BigDecimal max) {}

    record SkuPriceInfo(
            UUID skuId,
            String partNumber,
            BigDecimal unitPrice,
            String sellUnit
    ) {}

    record AttributeSummary(int id, String key, String label, String dataType, String filterWidget) {}
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/ProductApi.java
git commit -m "feat: create ProductApi interface with product/SKU/attribute methods and records"
```

---

### Task 3: Create SearchApi interface

Extract search methods from `CatalogApi` into `SearchApi`. Uses `ProductApi.ProductGroupSummary`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/SearchApi.java`

**Step 1: Create SearchApi.java**

```java
package com.storefront.catalog;

import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;

import java.util.List;

public interface SearchApi {

    Pagination<ProductApi.ProductGroupSummary> search(String query, PageRequest request);

    List<ProductApi.ProductGroupSummary> searchDropdown(String query, int limit);
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/SearchApi.java
git commit -m "feat: create SearchApi interface for search methods"
```

---

### Task 4: Create CategoryService in application layer

Move category methods from `ProductGroupService` into a new `CategoryService` that implements `CategoryApi`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/application/CategoryService.java`

**Step 1: Create CategoryService.java**

```java
package com.storefront.catalog.application;

import com.storefront.catalog.CategoryApi;
import com.storefront.catalog.domain.model.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
class CategoryService implements CategoryApi {

    private final CategoryRepository categoryRepository;

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
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL (old `ProductGroupService` still implements `CatalogApi`, no conflict yet)

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/application/CategoryService.java
git commit -m "feat: create CategoryService implementing CategoryApi"
```

---

### Task 5: Create ProductGroupService in application layer

Move product/SKU/attribute methods from old `ProductGroupService` into a new one that implements `ProductApi`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/application/ProductGroupService.java`

**Step 1: Create ProductGroupService.java**

```java
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
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/application/ProductGroupService.java
git commit -m "feat: create ProductGroupService implementing ProductApi"
```

---

### Task 6: Create SearchService in application layer

Move search methods into `SearchService` implementing `SearchApi`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/application/SearchService.java`

**Step 1: Create SearchService.java**

```java
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
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/application/SearchService.java
git commit -m "feat: create SearchService implementing SearchApi"
```

---

### Task 7: Create CategoryController in interfaces layer

Extract category endpoints from `ProductController` into `CategoryController`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/interfaces/CategoryController.java`

**Step 1: Create CategoryController.java**

```java
package com.storefront.catalog.interfaces;

import com.storefront.catalog.CategoryApi;
import com.storefront.catalog.ProductApi;
import com.storefront.shared.SliceRequest;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/catalog")
@RequiredArgsConstructor
class CategoryController {

    private final CategoryApi categoryApi;
    private final ProductApi productApi;

    @GetMapping("/categories/top-level")
    public String topLevelCategories(Model model) {
        var categories = categoryApi.findTopLevelCategories();
        model.addAttribute("categories", categories);
        return "catalog/category/top-level";
    }

    @GetMapping("/category/{slug}")
    public String browseCategory(
            @PathVariable String slug,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "48") int size,
            HttpServletRequest  request,
            HttpServletResponse response,
            Model model) {

        var category = categoryApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new CategoryNotFoundException(slug));

        var sliceRequest = SliceRequest.of(page, size);
        var slice = productApi.browseByCategory(category.path(), sliceRequest);
        var children = categoryApi.findChildCategories(category.id());
        var breadcrumb = categoryApi.findBreadcrumb(category.path());
        var attributes = productApi.findFilterableAttributes(category.id());

        model.addAttribute("category", category);
        model.addAttribute("groups", slice.items());
        model.addAttribute("hasMore", slice.hasMore());
        model.addAttribute("nextPage", page + 1);
        model.addAttribute("children", children);
        model.addAttribute("breadcrumb", breadcrumb);
        model.addAttribute("attributes", attributes);

        HtmxResponse.pushUrl(response, "/catalog/category/" + slug + "?page=" + page);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/category/content-with-sidebar";
        }
        return "catalog/category/page";
    }

    @GetMapping("/category/{slug}/children")
    public String categoryChildren(
            @PathVariable String slug,
            Model model) {

        var category = categoryApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new CategoryNotFoundException(slug));

        var children = categoryApi.findChildCategories(category.id());
        model.addAttribute("children", children);
        return "catalog/category/children";
    }

    @ResponseStatus(HttpStatus.NOT_FOUND)
    static class CategoryNotFoundException extends RuntimeException {
        CategoryNotFoundException(String slug) {
            super("Category not found: " + slug);
        }
    }
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL (old `ProductController` still exists, route conflicts won't occur until we delete it)

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/interfaces/CategoryController.java
git commit -m "feat: create CategoryController for category endpoints"
```

---

### Task 8: Create new ProductController in interfaces layer

Extract product detail/filter endpoints from old `ProductController`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/interfaces/ProductController.java`

**Step 1: Create ProductController.java**

```java
package com.storefront.catalog.interfaces;

import com.storefront.catalog.CategoryApi;
import com.storefront.catalog.ProductApi;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import com.storefront.shared.web.HtmxResponse;

import java.math.BigDecimal;
import java.util.*;

@Controller
@RequestMapping("/catalog")
@RequiredArgsConstructor
class ProductController {

    private final ProductApi productApi;
    private final CategoryApi categoryApi;

    @GetMapping("/product/{slug}")
    public String productGroup(
            @PathVariable String slug,
            HttpServletRequest request,
            Model model) {

        var group = productApi.findProductGroupBySlug(slug)
                .orElseThrow(() -> new ProductGroupNotFoundException(slug));

        var columns = productApi.findColumnConfig(group.id());
        var breadcrumb = categoryApi.findBreadcrumb(group.categoryPath());

        var allSkuIds = productApi.findMatchingSkuIds(group.id(), Map.of(), Map.of());
        var skuRows = productApi.findVariantTable(group.id(), allSkuIds);
        var facets = productApi.findFacetCounts(group.id(), allSkuIds);

        model.addAttribute("group", group);
        model.addAttribute("columns", columns);
        model.addAttribute("breadcrumb", breadcrumb);
        model.addAttribute("skuRows", skuRows);
        model.addAttribute("facets", facets);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/product/content";
        }
        return "catalog/product/page";
    }

    @GetMapping("/product/{slug}/filter")
    public String filterProductGroup(
            @PathVariable String slug,
            @RequestParam Map<String, String> allParams,
            Model model) {

        var group = productApi.findProductGroupBySlug(slug)
                .orElseThrow(() -> new ProductGroupNotFoundException(slug));

        var columns = productApi.findColumnConfig(group.id());

        Map<Integer, List<Integer>> enumFilters = new HashMap<>();
        Map<Integer, ProductApi.NumericRange> rangeFilters = new HashMap<>();
        parseFilterParams(allParams, enumFilters, rangeFilters);

        var matchingSkuIds = productApi.findMatchingSkuIds(group.id(), enumFilters, rangeFilters);
        var skuRows = productApi.findVariantTable(group.id(), matchingSkuIds);
        var facets = productApi.findFacetCounts(group.id(), matchingSkuIds);

        model.addAttribute("group", group);
        model.addAttribute("columns", columns);
        model.addAttribute("skuRows", skuRows);
        model.addAttribute("facets", facets);
        model.addAttribute("activeFilters", allParams);

        return "catalog/product/filtered";
    }

    private void parseFilterParams(Map<String, String> params,
                                    Map<Integer, List<Integer>> enumFilters,
                                    Map<Integer, ProductApi.NumericRange> rangeFilters) {
        for (var entry : params.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();

            if (key.startsWith("enum_") && !value.isBlank()) {
                try {
                    int attrId = Integer.parseInt(key.substring(5));
                    List<Integer> optionIds = Arrays.stream(value.split(","))
                            .map(String::trim)
                            .filter(s -> !s.isEmpty())
                            .map(Integer::parseInt)
                            .toList();
                    if (!optionIds.isEmpty()) {
                        enumFilters.put(attrId, optionIds);
                    }
                } catch (NumberFormatException ignored) {}
            }

            if (key.startsWith("range_min_") && !value.isBlank()) {
                try {
                    int attrId = Integer.parseInt(key.substring(10));
                    BigDecimal min = new BigDecimal(value);
                    String maxKey = "range_max_" + attrId;
                    BigDecimal max = params.containsKey(maxKey)
                            ? new BigDecimal(params.get(maxKey))
                            : new BigDecimal("999999");
                    rangeFilters.put(attrId, new ProductApi.NumericRange(min, max));
                } catch (NumberFormatException ignored) {}
            }
        }
    }

    @ResponseStatus(HttpStatus.NOT_FOUND)
    static class ProductGroupNotFoundException extends RuntimeException {
        ProductGroupNotFoundException(String slug) {
            super("Product group not found: " + slug);
        }
    }
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/interfaces/ProductController.java
git commit -m "feat: create new ProductController for product detail endpoints"
```

---

### Task 9: Create SearchController in interfaces layer

Extract search endpoints from old `ProductController`.

**Files:**
- Create: `src/main/java/com/storefront/catalog/interfaces/SearchController.java`

**Step 1: Create SearchController.java**

```java
package com.storefront.catalog.interfaces;

import com.storefront.catalog.ProductApi;
import com.storefront.catalog.SearchApi;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Controller
@RequestMapping("/catalog")
@RequiredArgsConstructor
class SearchController {

    private final SearchApi searchApi;

    @GetMapping("/search/dropdown")
    public String searchDropdown(
            @RequestParam(defaultValue = "") String q,
            Model model,
            HttpServletResponse response) {

        if (q.isBlank()) {
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);
            return null;
        }

        if (q.length() < 2) {
            return "catalog/search/dropdown-empty";
        }

        var results = searchApi.searchDropdown(q, 10);

        model.addAttribute("results", results);
        model.addAttribute("totalItems", results.size());
        model.addAttribute("query", q);

        return "catalog/search/dropdown";
    }

    @GetMapping("/search")
    public String search(
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "48") int size,
            HttpServletRequest  request,
            HttpServletResponse response,
            Model model) {

        var pageRequest = PageRequest.of(page, size, "relevance");
        var results = q.isBlank()
                ? Pagination.<ProductApi.ProductGroupSummary>empty(pageRequest)
                : searchApi.search(q, pageRequest);

        model.addAttribute("results", results.items());
        model.addAttribute("totalItems", results.totalItems());
        model.addAttribute("totalPages", results.totalPages());
        model.addAttribute("currentPage", results.page());
        model.addAttribute("hasNext", results.hasNext());
        model.addAttribute("hasPrev", results.hasPrevious());
        model.addAttribute("query", q);

        HtmxResponse.pushUrl(response, "/catalog/search?q=" + URLEncoder.encode(q, StandardCharsets.UTF_8) + "&page=" + page);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/search/content";
        }
        return "catalog/search/page";
    }
}
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 3: Commit**

```bash
git add src/main/java/com/storefront/catalog/interfaces/SearchController.java
git commit -m "feat: create SearchController for search endpoints"
```

---

### Task 10: Update domain repository imports

Switch all 4 domain repository interfaces from `CatalogApi.*` imports to `CategoryApi.*` / `ProductApi.*`.

**Files:**
- Modify: `src/main/java/com/storefront/catalog/domain/model/CategoryRepository.java`
- Modify: `src/main/java/com/storefront/catalog/domain/model/ProductGroupRepository.java`
- Modify: `src/main/java/com/storefront/catalog/domain/model/SkuRepository.java`
- Modify: `src/main/java/com/storefront/catalog/domain/model/AttributeRepository.java`

**Step 1: Update CategoryRepository.java**

Replace imports:
```
CatalogApi.CategoryBreadcrumb → CategoryApi.CategoryBreadcrumb
CatalogApi.CategoryNode       → CategoryApi.CategoryNode
```

**Step 2: Update ProductGroupRepository.java**

Replace imports:
```
CatalogApi.ProductGroupDetail  → ProductApi.ProductGroupDetail
CatalogApi.ProductGroupSummary → ProductApi.ProductGroupSummary
```

**Step 3: Update SkuRepository.java**

Replace imports:
```
CatalogApi.NumericRange  → ProductApi.NumericRange
CatalogApi.SkuPriceInfo  → ProductApi.SkuPriceInfo
CatalogApi.SkuRow        → ProductApi.SkuRow
```

**Step 4: Update AttributeRepository.java**

Replace imports:
```
CatalogApi.AttributeSummary → ProductApi.AttributeSummary
CatalogApi.ColumnConfig     → ProductApi.ColumnConfig
CatalogApi.FacetGroup       → ProductApi.FacetGroup
```

**Step 5: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL (old CatalogApi still exists, both old and new types coexist)

**Step 6: Commit**

```bash
git add src/main/java/com/storefront/catalog/domain/model/
git commit -m "refactor: update domain repository imports from CatalogApi to sub-APIs"
```

---

### Task 11: Update infrastructure repository imports

Switch all 4 jOOQ repository implementations from `CatalogApi.*` imports to `CategoryApi.*` / `ProductApi.*`.

**Files:**
- Modify: `src/main/java/com/storefront/catalog/infrastructure/JooqCategoryRepository.java`
- Modify: `src/main/java/com/storefront/catalog/infrastructure/JooqProductGroupRepository.java`
- Modify: `src/main/java/com/storefront/catalog/infrastructure/JooqSkuRepository.java`
- Modify: `src/main/java/com/storefront/catalog/infrastructure/JooqAttributeRepository.java`

**Step 1: Update JooqCategoryRepository.java**

Replace imports:
```
CatalogApi.CategoryBreadcrumb → CategoryApi.CategoryBreadcrumb
CatalogApi.CategoryNode       → CategoryApi.CategoryNode
```

**Step 2: Update JooqProductGroupRepository.java**

Replace imports:
```
CatalogApi.ProductGroupDetail  → ProductApi.ProductGroupDetail
CatalogApi.ProductGroupSummary → ProductApi.ProductGroupSummary
```

**Step 3: Update JooqSkuRepository.java**

Replace imports:
```
CatalogApi.NumericRange  → ProductApi.NumericRange
CatalogApi.SkuPriceInfo  → ProductApi.SkuPriceInfo
CatalogApi.SkuRow        → ProductApi.SkuRow
```

**Step 4: Update JooqAttributeRepository.java**

Replace imports:
```
CatalogApi.AttributeSummary → ProductApi.AttributeSummary
CatalogApi.ColumnConfig     → ProductApi.ColumnConfig
CatalogApi.FacetGroup       → ProductApi.FacetGroup
CatalogApi.FacetOption      → ProductApi.FacetOption
```

**Step 5: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 6: Commit**

```bash
git add src/main/java/com/storefront/catalog/infrastructure/
git commit -m "refactor: update infrastructure repository imports from CatalogApi to sub-APIs"
```

---

### Task 12: Update cross-module consumers

Update `HomeController` and any other files outside the catalog module that reference `CatalogApi`.

**Files:**
- Modify: `src/main/java/com/storefront/HomeController.java` — change `CatalogApi` → `CategoryApi`
- Modify: `src/main/java/com/storefront/StorefrontApplication.java` — update comment (line 11)
- Check: `src/main/java/com/storefront/cart/CartApi.java` — comment only, update reference

**Step 1: Update HomeController.java**

Replace:
```java
import com.storefront.catalog.CatalogApi;
```
With:
```java
import com.storefront.catalog.CategoryApi;
```

Replace:
```java
private final CatalogApi catalogApi;
```
With:
```java
private final CategoryApi categoryApi;
```

**Step 2: Update StorefrontApplication.java comment**

Replace line 11:
```java
 *   com.storefront.catalog   — products, categories (public: CatalogApi)
```
With:
```java
 *   com.storefront.catalog   — products, categories (public: CategoryApi, ProductApi, SearchApi)
```

**Step 3: Update CartApi.java comment**

Replace:
```java
 *   - SKU exists and is active (via CatalogApi)
```
With:
```java
 *   - SKU exists and is active (via ProductApi)
```

**Step 4: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add src/main/java/com/storefront/HomeController.java src/main/java/com/storefront/StorefrontApplication.java src/main/java/com/storefront/cart/CartApi.java
git commit -m "refactor: update cross-module consumers from CatalogApi to sub-APIs"
```

---

### Task 13: Update JTE template imports

All 15 JTE templates import `CatalogApi.*` records. Update each to use `CategoryApi.*` or `ProductApi.*`.

**Files to modify** (grouped by new import source):

**CategoryApi imports:**
- `templates/jte/home/page.jte` — `CategorySection` → `CategoryApi.CategorySection`
- `templates/jte/home/content-with-sidebar.jte` — `CategorySection` → `CategoryApi.CategorySection`
- `templates/jte/home/content.jte` — `CategorySection` → `CategoryApi.CategorySection`
- `templates/jte/catalog/category/page.jte` — `CategoryNode`, `CategoryBreadcrumb` → `CategoryApi.*`; `ProductGroupSummary`, `AttributeSummary` → `ProductApi.*`
- `templates/jte/catalog/category/content-with-sidebar.jte` — `CategoryNode`, `CategoryBreadcrumb` → `CategoryApi.*`; `ProductGroupSummary`, `AttributeSummary` → `ProductApi.*`
- `templates/jte/catalog/category/content.jte` — `CategoryNode`, `CategoryBreadcrumb` → `CategoryApi.*`; `ProductGroupSummary` → `ProductApi.*`
- `templates/jte/catalog/category/children.jte` — `CategoryNode` → `CategoryApi.CategoryNode`
- `templates/jte/catalog/category/top-level.jte` — `CategoryNode` → `CategoryApi.CategoryNode`
- `templates/jte/catalog/category/filter-sidebar.jte` — `AttributeSummary` → `ProductApi.*`; `CategoryNode` → `CategoryApi.*`

**ProductApi imports:**
- `templates/jte/catalog/product/page.jte` — all → `ProductApi.*`, except `CategoryBreadcrumb` → `CategoryApi.*`
- `templates/jte/catalog/product/content.jte` — all → `ProductApi.*`, except `CategoryBreadcrumb` → `CategoryApi.*`
- `templates/jte/catalog/product/filtered.jte` — all → `ProductApi.*`
- `templates/jte/catalog/product/filter-panel.jte` — all → `ProductApi.*`
- `templates/jte/catalog/product/filter-facet.jte` — all → `ProductApi.*`
- `templates/jte/catalog/product/variant-table.jte` — all → `ProductApi.*`
- `templates/jte/catalog/search/content.jte` — `ProductGroupSummary` → `ProductApi.*`
- `templates/jte/catalog/search/page.jte` — `ProductGroupSummary` → `ProductApi.*`
- `templates/jte/catalog/search/dropdown.jte` — `ProductGroupSummary` → `ProductApi.*`

**Step 1: Replace all `CatalogApi.Category*` imports with `CategoryApi.Category*`**

In every `.jte` file, find-and-replace:
```
@import com.storefront.catalog.CatalogApi.CategoryNode      → @import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.CatalogApi.CategoryBreadcrumb → @import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.CatalogApi.CategorySection    → @import com.storefront.catalog.CategoryApi.CategorySection
```

**Step 2: Replace all `CatalogApi.Product*` / `CatalogApi.Sku*` / etc. imports with `ProductApi.*`**

In every `.jte` file, find-and-replace:
```
@import com.storefront.catalog.CatalogApi.ProductGroupSummary → @import com.storefront.catalog.ProductApi.ProductGroupSummary
@import com.storefront.catalog.CatalogApi.ProductGroupDetail  → @import com.storefront.catalog.ProductApi.ProductGroupDetail
@import com.storefront.catalog.CatalogApi.SkuRow              → @import com.storefront.catalog.ProductApi.SkuRow
@import com.storefront.catalog.CatalogApi.ColumnConfig        → @import com.storefront.catalog.ProductApi.ColumnConfig
@import com.storefront.catalog.CatalogApi.FacetGroup          → @import com.storefront.catalog.ProductApi.FacetGroup
@import com.storefront.catalog.CatalogApi.AttributeSummary    → @import com.storefront.catalog.ProductApi.AttributeSummary
```

**Step 3: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL

**Step 4: Commit**

```bash
git add src/main/resources/templates/jte/
git commit -m "refactor: update JTE template imports from CatalogApi to sub-APIs"
```

---

### Task 14: Delete old files and CatalogApi

Remove the old `CatalogApi`, old `ProductGroupService`, and old `ProductController`. Delete the empty `group/` and `product/` packages.

**Files:**
- Delete: `src/main/java/com/storefront/catalog/CatalogApi.java`
- Delete: `src/main/java/com/storefront/catalog/group/ProductGroupService.java`
- Delete: `src/main/java/com/storefront/catalog/product/ProductController.java`
- Delete: `src/main/java/com/storefront/catalog/group/` (empty directory)
- Delete: `src/main/java/com/storefront/catalog/product/` (empty directory)

**Step 1: Delete old files**

```bash
rm src/main/java/com/storefront/catalog/CatalogApi.java
rm src/main/java/com/storefront/catalog/group/ProductGroupService.java
rm src/main/java/com/storefront/catalog/product/ProductController.java
rmdir src/main/java/com/storefront/catalog/group
rmdir src/main/java/com/storefront/catalog/product
```

**Step 2: Verify it compiles**

```bash
./gradlew compileJava 2>&1 | tail -5
```

Expected: BUILD SUCCESSFUL. If there are any remaining references to `CatalogApi`, fix them.

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: delete CatalogApi and old group/product packages"
```

---

### Task 15: Final verification

Ensure everything compiles, the application starts, and routes work.

**Step 1: Full build**

```bash
./gradlew build 2>&1 | tail -10
```

Expected: BUILD SUCCESSFUL

**Step 2: Grep for stale CatalogApi references**

```bash
grep -r "CatalogApi" src/ --include="*.java" --include="*.jte" || echo "No stale references"
```

Expected: "No stale references"

**Step 3: Verify final file structure**

Expected layout:
```
src/main/java/com/storefront/catalog/
├── CategoryApi.java
├── ProductApi.java
├── SearchApi.java
├── application/
│   ├── CategoryService.java
│   ├── ProductGroupService.java
│   └── SearchService.java
├── domain/
│   └── model/
│       ├── AttributeRepository.java
│       ├── CategoryRepository.java
│       ├── ProductGroupRepository.java
│       └── SkuRepository.java
├── infrastructure/
│   ├── JooqAttributeRepository.java
│   ├── JooqCategoryRepository.java
│   ├── JooqProductGroupRepository.java
│   └── JooqSkuRepository.java
└── interfaces/
    ├── CategoryController.java
    ├── ProductController.java
    └── SearchController.java
```

**Step 4: Start the application (requires Docker for Postgres/Redis)**

```bash
./gradlew bootRunDev
```

Verify these routes still work:
- `GET /` — home page with category sections
- `GET /catalog/categories/top-level` — sidebar categories
- `GET /catalog/category/{slug}` — category browse
- `GET /catalog/product/{slug}` — product detail
- `GET /catalog/search?q=test` — search results
- `GET /catalog/search/dropdown?q=test` — search dropdown

**Step 5: Final commit**

```bash
git commit --allow-empty -m "chore: catalog module reorganization complete"
```
