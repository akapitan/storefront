package com.storefront.catalog.product;

import com.storefront.catalog.CatalogApi;
import com.storefront.shared.PageRequest;
import com.storefront.shared.SliceRequest;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

@Controller
@RequestMapping("/catalog")
@RequiredArgsConstructor
class ProductController {

    private final CatalogApi catalogApi;

    // ─── Sidebar categories ───────────────────────────────────────────────────

    @GetMapping("/categories/top-level")
    public String topLevelCategories(Model model) {
        var categories = catalogApi.findTopLevelCategories();
        model.addAttribute("categories", categories);
        return "catalog/top-level-categories";
    }

    // ─── Category browse ───────────────────────────────────────────────────────

    @GetMapping("/category/{slug}")
    public String browseCategory(
            @PathVariable String slug,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "48") int size,
            HttpServletRequest  request,
            HttpServletResponse response,
            Model model) {

        var category = catalogApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new CategoryNotFoundException(slug));

        var sliceRequest = SliceRequest.of(page, size);
        var slice = catalogApi.browseByCategory(category.path(), sliceRequest);
        var children = catalogApi.findChildCategories(category.id());
        var breadcrumb = catalogApi.findBreadcrumb(category.path());
        var attributes = catalogApi.findFilterableAttributes(category.id());

        model.addAttribute("category", category);
        model.addAttribute("groups", slice.items());
        model.addAttribute("hasMore", slice.hasMore());
        model.addAttribute("nextPage", page + 1);
        model.addAttribute("children", children);
        model.addAttribute("breadcrumb", breadcrumb);
        model.addAttribute("attributes", attributes);

        HtmxResponse.pushUrl(response, "/catalog/category/" + slug + "?page=" + page);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/category-browse-content-with-sidebar";
        }
        return "catalog/category-browse";
    }

    @GetMapping("/category/{slug}/children")
    public String categoryChildren(
            @PathVariable String slug,
            Model model) {

        var category = catalogApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new CategoryNotFoundException(slug));

        var children = catalogApi.findChildCategories(category.id());
        model.addAttribute("children", children);
        return "catalog/category-children";
    }

    // ─── Product group page ────────────────────────────────────────────────────

    @GetMapping("/product/{slug}")
    public String productGroup(
            @PathVariable String slug,
            HttpServletRequest request,
            Model model) {

        var group = catalogApi.findProductGroupBySlug(slug)
                .orElseThrow(() -> new ProductGroupNotFoundException(slug));

        var columns = catalogApi.findColumnConfig(group.id());
        var breadcrumb = catalogApi.findBreadcrumb(group.categoryPath());

        // Initial load: all SKUs (no filters)
        var allSkuIds = catalogApi.findMatchingSkuIds(group.id(), Map.of(), Map.of());
        var skuRows = catalogApi.findVariantTable(group.id(), allSkuIds);
        var facets = catalogApi.findFacetCounts(group.id(), allSkuIds);

        model.addAttribute("group", group);
        model.addAttribute("columns", columns);
        model.addAttribute("breadcrumb", breadcrumb);
        model.addAttribute("skuRows", skuRows);
        model.addAttribute("facets", facets);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/product-group-content";
        }
        return "catalog/product-group";
    }

    @GetMapping("/product/{slug}/filter")
    public String filterProductGroup(
            @PathVariable String slug,
            @RequestParam Map<String, String> allParams,
            Model model) {

        var group = catalogApi.findProductGroupBySlug(slug)
                .orElseThrow(() -> new ProductGroupNotFoundException(slug));

        var columns = catalogApi.findColumnConfig(group.id());

        // Parse filter params into enum and range filters
        Map<Integer, List<Integer>> enumFilters = new HashMap<>();
        Map<Integer, CatalogApi.NumericRange> rangeFilters = new HashMap<>();
        parseFilterParams(allParams, enumFilters, rangeFilters);

        var matchingSkuIds = catalogApi.findMatchingSkuIds(group.id(), enumFilters, rangeFilters);
        var skuRows = catalogApi.findVariantTable(group.id(), matchingSkuIds);
        var facets = catalogApi.findFacetCounts(group.id(), matchingSkuIds);

        model.addAttribute("group", group);
        model.addAttribute("columns", columns);
        model.addAttribute("skuRows", skuRows);
        model.addAttribute("facets", facets);
        model.addAttribute("activeFilters", allParams);

        return "catalog/product-group-filtered";
    }

    // ─── Search ────────────────────────────────────────────────────────────────

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
            return "catalog/search-dropdown-empty";
        }

        var results = catalogApi.searchDropdown(q, 10);

        model.addAttribute("results", results);
        model.addAttribute("totalItems", results.size());
        model.addAttribute("query", q);

        return "catalog/search-dropdown";
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
                ? com.storefront.shared.Pagination.<CatalogApi.ProductGroupSummary>empty(pageRequest)
                : catalogApi.search(q, pageRequest);

        model.addAttribute("results", results.items());
        model.addAttribute("totalItems", results.totalItems());
        model.addAttribute("totalPages", results.totalPages());
        model.addAttribute("currentPage", results.page());
        model.addAttribute("hasNext", results.hasNext());
        model.addAttribute("hasPrev", results.hasPrevious());
        model.addAttribute("query", q);

        HtmxResponse.pushUrl(response, "/catalog/search?q=" + URLEncoder.encode(q, StandardCharsets.UTF_8) + "&page=" + page);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/search-results-content";
        }
        return "catalog/search-results";
    }

    // ─── Filter param parser ───────────────────────────────────────────────────

    private void parseFilterParams(Map<String, String> params,
                                    Map<Integer, List<Integer>> enumFilters,
                                    Map<Integer, CatalogApi.NumericRange> rangeFilters) {
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
                    rangeFilters.put(attrId, new CatalogApi.NumericRange(min, max));
                } catch (NumberFormatException ignored) {}
            }
        }
    }

    // ─── Exceptions ────────────────────────────────────────────────────────────

    @ResponseStatus(HttpStatus.NOT_FOUND)
    static class CategoryNotFoundException extends RuntimeException {
        CategoryNotFoundException(String slug) {
            super("Category not found: " + slug);
        }
    }

    @ResponseStatus(HttpStatus.NOT_FOUND)
    static class ProductGroupNotFoundException extends RuntimeException {
        ProductGroupNotFoundException(String slug) {
            super("Product group not found: " + slug);
        }
    }
}
