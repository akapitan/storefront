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
