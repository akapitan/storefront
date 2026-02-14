package com.storefront.shared;

import java.util.Optional;

/**
 * SliceRequest — input for no-count {@link Slice} queries.
 * ══════════════════════════════════════════════════════════
 *
 * Supports two pagination modes:
 *
 * <b>Offset mode</b> — simple, works with any ORDER BY:
 * <pre>{@code
 * var request = SliceRequest.of(page, size, sort);
 * // Repository uses LIMIT size+1 OFFSET page*size
 * }</pre>
 *
 * <b>Keyset / cursor mode</b> — no OFFSET, O(1) regardless of depth.
 * Best for infinite scroll on large tables:
 * <pre>{@code
 * var request = SliceRequest.withCursor(size, sort, lastSeenCursor);
 * // Repository uses WHERE id > :cursor LIMIT size+1 (no OFFSET)
 * }</pre>
 *
 * Cursor format is opaque to callers — the repository encodes/decodes it.
 * A simple approach: base64(lastSeenId). A richer approach: base64(JSON of
 * all sort columns + id) for multi-column stable sorts.
 *
 * HTMX infinite scroll usage:
 * <pre>{@code
 * // Controller returns the next-cursor in an HX-Trigger header
 * // so the client can embed it in the next hx-get request param
 * response.setHeader("HX-Trigger",
 *         "{\"nextCursor\": \"" + slice.nextCursor().orElse("") + "\"}");
 * }</pre>
 */
public record SliceRequest(

        /** Zero-based page index for offset mode. -1 for cursor mode. */
        int page,

        /** Items per slice. Clamped to [1, MAX_SLICE_SIZE]. */
        int pageSize,

        /** Sort key — interpreted by the repository. */
        String sort,

        /**
         * Opaque cursor from the previous slice's {@link Slice#nextCursor()}.
         * Empty for the first request or when using offset mode.
         */
        Optional<String> cursor

) {

    public static final int MAX_SLICE_SIZE = 100;
    public static final int DEFAULT_SLICE_SIZE = 48;

    public SliceRequest {
        page     = Math.max(0, page);
        pageSize = Math.min(Math.max(1, pageSize), MAX_SLICE_SIZE);
        sort     = (sort == null || sort.isBlank()) ? "default" : sort.strip();
        cursor   = cursor == null ? Optional.empty() : cursor;
    }

    // ─── Factory methods ───────────────────────────────────────────────────────

    /** Offset-based slice — simplest, use for most cases. */
    public static SliceRequest of(int page, int pageSize, String sort) {
        return new SliceRequest(page, pageSize, sort, Optional.empty());
    }

    public static SliceRequest of(int page, int pageSize) {
        return new SliceRequest(page, pageSize, "default", Optional.empty());
    }

    public static SliceRequest firstSlice() {
        return new SliceRequest(0, DEFAULT_SLICE_SIZE, "default", Optional.empty());
    }

    /** Cursor-based slice — for infinite scroll on large tables. */
    public static SliceRequest withCursor(int pageSize, String sort, String cursor) {
        return new SliceRequest(-1, pageSize, sort,
                (cursor == null || cursor.isBlank()) ? Optional.empty() : Optional.of(cursor));
    }

    // ─── Derived helpers ───────────────────────────────────────────────────────

    /** Whether this is a cursor-based request. */
    public boolean isCursorBased() {
        return cursor.isPresent();
    }

    /**
     * SQL OFFSET for offset-based mode.
     * Returns 0 for cursor-based requests (cursor replaces OFFSET in the WHERE clause).
     */
    public int offset() {
        return isCursorBased() ? 0 : page * pageSize;
    }

    /**
     * The fetch size to pass to jOOQ LIMIT — always pageSize + 1.
     * The extra row lets {@link Slice#of} detect hasMore without COUNT(*).
     */
    public int fetchSize() {
        return pageSize + 1;
    }

    /** Returns a SliceRequest for the next offset-based page. */
    public SliceRequest next() {
        return new SliceRequest(page + 1, pageSize, sort, Optional.empty());
    }
}
