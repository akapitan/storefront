package com.storefront.catalog.interfaces;

import com.storefront.catalog.CategoryApi;
import com.storefront.catalog.ProductApi;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.Map;

@Controller
@RequestMapping("/catalog")
@RequiredArgsConstructor
class CategoryController {

    private final CategoryApi categoryApi;
    private final ProductApi productApi;

    @GetMapping("/categories/top-level")
    public String topLevelCategories(Model model) {
        model.addAttribute("categories", categoryApi.findTopLevelCategories());
        return "catalog/category/top-level";
    }

    @GetMapping("/category/{slug}")
    public String browseCategory(
            @PathVariable String slug,
            @RequestParam Map<String, String> allParams,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model) {

        var category = categoryApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new CategoryNotFoundException(slug));

        var parsed = FilterParamParser.parse(allParams);
        var enumFilters = parsed.enumFilters();
        var rangeFilters = parsed.rangeFilters();

        model.addAttribute("category", category);
        model.addAttribute("breadcrumb", categoryApi.findBreadcrumb(category.path()));

        HtmxResponse.pushUrl(response, buildUrl(slug, allParams));

        String viewMode;
        if (category.depth() == 0) {
            viewMode = "top-level";
            model.addAttribute("children", categoryApi.findChildCategories(category.id()));

        } else if (!category.isLeaf()) {
            viewMode = "mid-level";
            model.addAttribute("filteredChildren",
                    categoryApi.findFilteredChildren(category.id(), category.path(),
                            enumFilters, rangeFilters));
            model.addAttribute("facets",
                    categoryApi.findMidLevelFacets(category.path(), enumFilters, rangeFilters));
            model.addAttribute("enumFilters", enumFilters);
            model.addAttribute("rangeFilters", rangeFilters);

        } else {
            viewMode = "leaf";
            model.addAttribute("groupTables",
                    categoryApi.findLeafGroupTables(category.id(), category.path(),
                            enumFilters, rangeFilters));
            model.addAttribute("facets",
                    categoryApi.findLeafFacets(category.id(), enumFilters, rangeFilters));
            model.addAttribute("enumFilters", enumFilters);
            model.addAttribute("rangeFilters", rangeFilters);
        }

        model.addAttribute("viewMode", viewMode);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/category/content-with-sidebar";
        }
        return "catalog/category/page";
    }

    @GetMapping("/category/{slug}/children")
    public String categoryChildren(@PathVariable String slug, Model model) {
        var category = categoryApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new CategoryNotFoundException(slug));
        model.addAttribute("children", categoryApi.findChildCategories(category.id()));
        return "catalog/category/children";
    }

    private String buildUrl(String slug, Map<String, String> params) {
        var builder = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .replacePath("/catalog/category/{slug}");

        params.entrySet().stream()
                .filter(e -> e.getKey().startsWith("enum_") || e.getKey().startsWith("range_"))
                .forEach(e -> builder.queryParam(e.getKey(), e.getValue()));

        return builder.buildAndExpand(slug).toUriString();
    }

    @ResponseStatus(HttpStatus.NOT_FOUND)
    static class CategoryNotFoundException extends RuntimeException {
        CategoryNotFoundException(String slug) {
            super("Category not found: " + slug);
        }
    }
}
