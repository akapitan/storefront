package com.storefront;

import com.storefront.catalog.CatalogApi;
import com.storefront.catalog.CatalogApi.CategoryGroup;
import com.storefront.catalog.CatalogApi.CategoryNode;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
@RequiredArgsConstructor
class HomeController {

    private final CatalogApi catalogApi;

    @GetMapping("/")
    public String home(HttpServletRequest request, Model model) {
        var categories = catalogApi.findTopLevelCategories();
        model.addAttribute("categories", categories);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "home-content";
        }
        return "index";
    }

    @GetMapping("/category/{slug}")
    public String categoryExpanded(@PathVariable String slug,
                                   HttpServletRequest request,
                                   Model model) {
        var category = catalogApi.findCategoryBySlug(slug)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));

        var descendants = catalogApi.findCategoryDescendants(category.path());

        // Group: depth-1 nodes are section headers, depth-2 items belong to their parentId
        short parentDepth = category.depth();
        short headerDepth = (short) (parentDepth + 1);
        short leafDepth = (short) (parentDepth + 2);

        List<CategoryNode> headers = descendants.stream()
                .filter(n -> n.depth() == headerDepth)
                .toList();

        Map<Integer, List<CategoryNode>> itemsByParent = descendants.stream()
                .filter(n -> n.depth() == leafDepth)
                .collect(Collectors.groupingBy(
                        n -> n.parentId() != null ? n.parentId() : 0));

        List<CategoryGroup> groups = new ArrayList<>();
        for (var header : headers) {
            var items = itemsByParent.getOrDefault(header.id(), List.of());
            groups.add(new CategoryGroup(header, items));
        }

        model.addAttribute("category", category);
        model.addAttribute("groups", groups);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "home-category-expanded-content";
        }
        return "home-category-expanded";
    }
}
