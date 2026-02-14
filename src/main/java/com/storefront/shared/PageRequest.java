package com.storefront.shared;

/**
 * PageRequest — input for offset-based {@link Pagination} queries.
 * ══════════════════════════════════════════════════════════════════
 *
 * Immutable value object. Construct from HTTP request params in controllers:
 *
 * <pre>{@code
 * @GetMapping("/products")
 * public String list(
 *         @RequestParam(defaultValue = "0")  int page,
 *         @RequestParam(defaultValue = "48") int size,
 *         @RequestParam(defaultValue = "default") String sort,
 *         Model model) {
 *
 *     var request = PageRequest.of(page, size, sort);
 *     var result  = productService.listByCategory(categoryId, request);
 *     model.addAttribute("page", result);
 *     return "catalog/product-grid :: grid";   // HTMX fragment
 * }
 * }</pre>
 */
public record PageRequest(

        /** Zero-based page index. Clamped to ≥ 0. */
        int page,

        /** Items per page. Clamped to [1, MAX_PAGE_SIZE]. */
        int pageSize,

        /** Sort key — interpreted by the repository (e.g. "price_asc", "name", "default"). */
        String sort

) {

    /** Hard cap on page size to prevent accidental large queries. */
    public static final int MAX_PAGE_SIZE = 100;

    /** Default page size matching McMaster-style dense product grids. */
    public static final int DEFAULT_PAGE_SIZE = 48;

    public PageRequest {
        page     = Math.max(0, page);
        pageSize = Math.min(Math.max(1, pageSize), MAX_PAGE_SIZE);
        sort     = (sort == null || sort.isBlank()) ? "default" : sort.strip();
    }

    // ─── Factory methods ───────────────────────────────────────────────────────

    public static PageRequest of(int page, int pageSize, String sort) {
        return new PageRequest(page, pageSize, sort);
    }

    public static PageRequest of(int page, int pageSize) {
        return new PageRequest(page, pageSize, "default");
    }

    public static PageRequest firstPage() {
        return new PageRequest(0, DEFAULT_PAGE_SIZE, "default");
    }

    // ─── Derived helpers ───────────────────────────────────────────────────────

    /** SQL OFFSET for this page. */
    public int offset() {
        return page * pageSize;
    }

    /** Returns a new PageRequest for the next page. */
    public PageRequest next() {
        return new PageRequest(page + 1, pageSize, sort);
    }

    /** Returns a new PageRequest for the previous page (floor 0). */
    public PageRequest previous() {
        return new PageRequest(Math.max(0, page - 1), pageSize, sort);
    }
}
