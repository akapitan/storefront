package com.storefront.catalog.interfaces;

import com.storefront.catalog.CategoryApi;
import com.storefront.catalog.ProductApi;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

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
