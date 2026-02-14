package com.storefront.shared;

import java.util.List;
import java.util.Optional;
import java.util.function.Function;

/**
 * Slice — lightweight page without total count.
 * ══════════════════════════════════════════════
 *
 * Use when the UI only needs to know if there are more items to load —
 * infinite scroll, "Load more" buttons, API cursors — and does NOT need
 * a total count or arbitrary page jumps.
 *
 * Advantage over {@link Pagination}: skips the expensive COUNT(*) query.
 * For large product catalogs this can be a significant performance win.
 *
 * How "hasMore" works:
 * Request pageSize + 1 rows from the DB. If you get pageSize + 1 back,
 * trim the extra row and set hasMore = true. If you get ≤ pageSize rows,
 * hasMore = false. This avoids any count query entirely.
 *
 * <pre>{@code
 * // In your repository — request one extra row to detect hasMore
 * int fetchSize = request.pageSize() + 1;
 * List<ProductSummary> rows = dsl
 *         .select(...)
 *         .from(PRODUCT)
 *         .where(conditions)
 *         .orderBy(PRODUCT.DISPLAY_ORDER.asc(), PRODUCT.ID.asc())  // stable sort required
 *         .limit(fetchSize)
 *         .offset(request.offset())
 *         .fetch(mapper);
 *
 * return Slice.of(rows, request);
 * }</pre>
 *
 * Keyset / cursor pagination (even faster for deep offsets):
 * Instead of OFFSET, pass the last-seen ID as a cursor and use
 * WHERE id > :cursor. Combine with {@link SliceRequest#cursor()}.
 *
 * @param <T> the type of items in this slice
 */
public record Slice<T>(

        /** The items in this slice (trimmed to pageSize — never includes the probe row). */
        List<T> items,

        /** Zero-based page index (offset-based) or -1 if cursor-based. */
        int page,

        /** Number of items requested per slice. */
        int pageSize,

        /** Whether more items exist after this slice. */
        boolean hasMore,

        /**
         * Opaque cursor pointing to the last item in this slice.
         * Non-empty when using keyset pagination. Pass back in the
         * next {@link SliceRequest} to fetch the following slice.
         */
        Optional<String> nextCursor

) {

    // ─── Factory methods ───────────────────────────────────────────────────────

    /**
     * Build a Slice from a raw result list that may contain one extra "probe" row.
     *
     * <p>The repository should fetch {@code request.pageSize() + 1} rows.
     * This method trims the list back to {@code pageSize} and sets
     * {@code hasMore} accordingly — no COUNT(*) required.
     *
     * @param rawRows  list of up to pageSize+1 items from the DB
     * @param request  the original slice request
     */
    public static <T> Slice<T> of(List<T> rawRows, SliceRequest request) {
        boolean hasMore = rawRows.size() > request.pageSize();
        List<T> items = hasMore
                ? rawRows.subList(0, request.pageSize())   // trim probe row
                : List.copyOf(rawRows);

        return new Slice<>(items, request.page(), request.pageSize(), hasMore, Optional.empty());
    }

    /**
     * Build a Slice with a cursor for keyset pagination.
     *
     * @param rawRows    list of up to pageSize+1 items
     * @param request    the original slice request
     * @param nextCursor opaque string cursor derived from the last item (e.g. base64-encoded ID)
     */
    public static <T> Slice<T> of(List<T> rawRows, SliceRequest request, String nextCursor) {
        boolean hasMore = rawRows.size() > request.pageSize();
        List<T> items = hasMore
                ? rawRows.subList(0, request.pageSize())
                : List.copyOf(rawRows);

        return new Slice<>(items, request.page(), request.pageSize(), hasMore,
                hasMore ? Optional.of(nextCursor) : Optional.empty());
    }

    /**
     * Empty slice — no results, no next page.
     */
    public static <T> Slice<T> empty(SliceRequest request) {
        return new Slice<>(List.of(), request.page(), request.pageSize(), false, Optional.empty());
    }

    // ─── Derived helpers ───────────────────────────────────────────────────────

    /** Whether this slice has any items. */
    public boolean isEmpty() {
        return items.isEmpty();
    }

    /** Number of items in this slice. */
    public int itemCount() {
        return items.size();
    }

    /** SQL OFFSET value for the current slice (offset-based pagination only). */
    public int offset() {
        return page * pageSize;
    }

    /**
     * Transform item type without changing slice metadata.
     *
     * <pre>{@code
     * Slice<ProductRecord> raw = repo.browseCategory(categoryId, request);
     * Slice<ProductCardDto> dto = raw.map(ProductCardDto::from);
     * }</pre>
     */
    public <U> Slice<U> map(Function<T, U> mapper) {
        return new Slice<>(
                items.stream().map(mapper).toList(),
                page,
                pageSize,
                hasMore,
                nextCursor
        );
    }
}
