package com.storefront.catalog.product;

import com.storefront.catalog.CatalogApi;
import com.storefront.shared.PageRequest;
import com.storefront.shared.SliceRequest;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * ProductController — HTMX-driven product catalog endpoints.
 *
 * All endpoints return either a full page or a Thymeleaf fragment
 * depending on whether the request is from HTMX or a direct browser load.
 *
 * Template naming convention:
 *   "catalog/product-grid-content"    → renders content area only
 *   "catalog/product-cards"           → renders cards for infinite scroll
 *   "catalog/product-detail"          → full page render
 *   "catalog/product-detail-content"  → detail content only
 *
 * HTMX patterns used:
 *   hx-get + hx-target   → swap product grid on filter change
 *   hx-push-url          → update browser URL without full navigation
 *   hx-trigger="revealed" on last card → infinite scroll trigger
 */
@Controller
@RequestMapping("/catalog")
@RequiredArgsConstructor
class ProductController {

    private final CatalogApi catalogApi;

    // ─── Product grid (category browse) ──────────────────────────────────────

    /**
     * Full category browse page.
     * HTMX requests:
     *   - targeting #main-content → return "content-wrapper" (SPA navigation)
     *   - targeting #product-grid → return "grid" (sort/filter updates)
     * Direct loads get the full page.
     */
    @GetMapping("/category/{categoryId}")
    public String browseCategory(
            @PathVariable UUID categoryId,
            @RequestParam(defaultValue = "0")    int    page,
            @RequestParam(defaultValue = "48")   int    size,
            @RequestParam(defaultValue = "default") String sort,
            HttpServletRequest  request,
            HttpServletResponse response,
            Model model) {

        var sliceRequest = SliceRequest.of(page, size, sort);
        var slice        = catalogApi.browseByCategory(categoryId, sliceRequest);

        model.addAttribute("products",  slice.items());
        model.addAttribute("hasMore",   slice.hasMore());
        model.addAttribute("nextPage",  page + 1);
        model.addAttribute("sort",      sort);
        model.addAttribute("categoryId", categoryId);

        // Push URL so browser back button works
        HtmxResponse.pushUrl(response, "/catalog/category/" + categoryId + "?page=" + page + "&sort=" + sort);

        // HTMX requests get the content template
        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/product-grid-content";
        }
        return "catalog/product-grid";
    }

    // ─── Infinite scroll — next slice ─────────────────────────────────────────

    /**
     * Called by HTMX when the last product card enters the viewport.
     * hx-trigger="revealed" on the last card triggers this endpoint.
     * Returns only the next batch of product cards (no surrounding layout).
     */
    @GetMapping("/category/{categoryId}/more")
    public String loadMore(
            @PathVariable UUID categoryId,
            @RequestParam int  page,
            @RequestParam(defaultValue = "48")   int    size,
            @RequestParam(defaultValue = "default") String sort,
            Model model) {

        var sliceRequest = SliceRequest.of(page, size, sort);
        var slice        = catalogApi.browseByCategory(categoryId, sliceRequest);

        model.addAttribute("products",  slice.items());
        model.addAttribute("hasMore",   slice.hasMore());
        model.addAttribute("nextPage",  page + 1);
        model.addAttribute("sort",      sort);
        return "catalog/product-cards";

    }

    // ─── Product search ───────────────────────────────────────────────────────

    /**
     * Full-text product search.
     * HTMX: triggered on input with hx-trigger="input changed delay:300ms".
     */
    @GetMapping("/search")
    public String search(
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "48") int size,
            HttpServletRequest  request,
            HttpServletResponse response,
            Model model) {

        var pageRequest = PageRequest.of(page, size, "relevance");
        var results     = q.isBlank()
                ? com.storefront.shared.Pagination.<CatalogApi.ProductSummary>empty(pageRequest)
                : catalogApi.search(q, pageRequest);

        model.addAttribute("results",     results.items());
        model.addAttribute("totalItems",  results.totalItems());
        model.addAttribute("totalPages",  results.totalPages());
        model.addAttribute("currentPage", results.page());
        model.addAttribute("hasNext",     results.hasNext());
        model.addAttribute("hasPrev",     results.hasPrevious());
        model.addAttribute("query",       q);

        HtmxResponse.pushUrl(response, "/catalog/search?q=" + q + "&page=" + page);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/search-results-content";
        }
        return "catalog/search-results";
    }

    // ─── Product detail ───────────────────────────────────────────────────────

    /**
     * Full product detail page.
     * HTMX requests get only the detail fragment (for SPA navigation).
     * Direct browser loads get the full page with layout.
     */
    @GetMapping("/product/{sku}")
    public String productDetail(
            @PathVariable String sku,
            HttpServletRequest request,
            Model model) {

        var product = catalogApi.findBySku(sku)
                .orElseThrow(() -> new ProductNotFoundException(sku));

        model.addAttribute("product", product);

        // For HTMX requests, return only the detail content template
        if (HtmxResponse.isHtmxRequest(request)) {
            return "catalog/product-detail-content";
        }
        return "catalog/product-detail";
    }

    // ─── Quick-view (HTMX modal fragment) ────────────────────────────────────

    /**
     * Returns a product quick-view template for HTMX modal.
     * Triggered by hx-get on a product card's "Quick view" button.
     */
    @GetMapping("/product/{sku}/quick-view")
    public String quickView(@PathVariable String sku, Model model) {
        var product = catalogApi.findBySku(sku)
                .orElseThrow(() -> new ProductNotFoundException(sku));
        model.addAttribute("product", product);
        return "catalog/product-quick-view";
    }

    // ─── Exception ────────────────────────────────────────────────────────────

    static class ProductNotFoundException extends RuntimeException {
        ProductNotFoundException(String sku) {
            super("Product not found: " + sku);
        }
    }
}
