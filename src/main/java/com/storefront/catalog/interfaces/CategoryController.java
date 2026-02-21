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
