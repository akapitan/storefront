package com.storefront.shared;

import java.util.List;
import java.util.function.Function;

/**
 * Pagination — offset-based page with total count.
 * ══════════════════════════════════════════════════
 *
 * Use when the UI needs to show a total count or jump to arbitrary pages
 * (e.g. "Page 3 of 47", numbered pagination controls).
 *
 * Cost: requires a COUNT(*) query alongside the data query.
 * For large tables this can be expensive — prefer {@link Slice} when
 * you only need next/prev navigation (infinite scroll, "load more").
 *
 * <pre>{@code
 * // Building from a jOOQ query result
 * int total = dsl.selectCount().from(PRODUCT).where(conditions).fetchOne(0, int.class);
 * List<ProductSummary> items = dsl.select(...).from(PRODUCT).where(conditions)
 *         .orderBy(PRODUCT.NAME)
 *         .limit(request.pageSize())
 *         .offset(request.offset())
 *         .fetch(mapper);
 *
 * return Pagination.of(items, total, request);
 * }</pre>
 *
 * @param <T> the type of items in this page
 */
public record Pagination<T>(

        /** The items on this page. */
        List<T> items,

        /** Total number of matching items across all pages. */
        int totalItems,

        /** Zero-based current page index. */
        int page,

        /** Number of items requested per page. */
        int pageSize,

        /** Total number of pages (derived). */
        int totalPages,

        /** Whether there is a page before this one. */
        boolean hasPrevious,

        /** Whether there is a page after this one. */
        boolean hasNext

) {

    // ─── Factory methods ───────────────────────────────────────────────────────

    /**
     * Construct a Pagination from items, a total count, and a {@link PageRequest}.
     */
    public static <T> Pagination<T> of(List<T> items, int totalItems, PageRequest request) {
        int totalPages = request.pageSize() == 0
                ? 1
                : (int) Math.ceil((double) totalItems / request.pageSize());

        return new Pagination<>(
                items,
                totalItems,
                request.page(),
                request.pageSize(),
                totalPages,
                request.page() > 0,
                request.page() < totalPages - 1
        );
    }

    /**
     * Construct an empty Pagination (zero results).
     */
    public static <T> Pagination<T> empty(PageRequest request) {
        return new Pagination<>(List.of(), 0, request.page(), request.pageSize(), 0, false, false);
    }

    // ─── Derived helpers ───────────────────────────────────────────────────────

    /** SQL OFFSET value for the current page. */
    public int offset() {
        return page * pageSize;
    }

    /** Whether this page has any items. */
    public boolean isEmpty() {
        return items.isEmpty();
    }

    /** Number of items on this specific page (may be less than pageSize on last page). */
    public int itemCount() {
        return items.size();
    }

    /**
     * Transform item type without changing pagination metadata.
     * Useful for mapping domain objects to DTOs before returning from a controller.
     *
     * <pre>{@code
     * Pagination<ProductRecord> raw = repo.listByCategory(categoryId, request);
     * Pagination<ProductSummaryDto> dto = raw.map(ProductSummaryDto::from);
     * }</pre>
     */
    public <U> Pagination<U> map(Function<T, U> mapper) {
        return new Pagination<>(
                items.stream().map(mapper).toList(),
                totalItems,
                page,
                pageSize,
                totalPages,
                hasPrevious,
                hasNext
        );
    }
}
