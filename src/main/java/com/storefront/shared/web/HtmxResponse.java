package com.storefront.shared.web;

import jakarta.servlet.http.HttpServletResponse;

/**
 * HtmxResponse — helper for setting HTMX response headers from controllers.
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * HTMX drives UI updates via HTTP response headers. Instead of scattering
 * magic header strings across controllers, use these typed helpers.
 *
 * Common patterns:
 * <pre>{@code
 * // Trigger a client-side event (e.g. update cart badge)
 * HtmxResponse.trigger(response, "cart:updated");
 *
 * // Redirect after a form submission
 * HtmxResponse.redirect(response, "/orders/" + orderId);
 *
 * // Force a full page refresh
 * HtmxResponse.refresh(response);
 *
 * // Re-render a specific target
 * HtmxResponse.retarget(response, "#search-results");
 * }</pre>
 *
 * @see <a href="https://htmx.org/reference/#response_headers">HTMX Response Headers</a>
 */
public final class HtmxResponse {

    private HtmxResponse() {}

    // ─── Trigger ──────────────────────────────────────────────────────────────

    /**
     * Fire a client-side event after the HTMX swap completes.
     * Listeners set up with hx-trigger="eventName from:body" will react.
     *
     * @param event event name, e.g. "cart:updated", "search:cleared"
     */
    public static void trigger(HttpServletResponse response, String event) {
        response.setHeader("HX-Trigger", event);
    }

    /**
     * Fire multiple events as a JSON object.
     *
     * @param eventsJson e.g. "{\"cart:updated\": null, \"toast:show\": \"Item added\"}"
     */
    public static void triggerJson(HttpServletResponse response, String eventsJson) {
        response.setHeader("HX-Trigger", eventsJson);
    }

    /**
     * Fire an event AFTER the swap settles (after CSS transitions finish).
     * Useful for triggering animations on newly-inserted elements.
     */
    public static void triggerAfterSettle(HttpServletResponse response, String event) {
        response.setHeader("HX-Trigger-After-Settle", event);
    }

    // ─── Navigation ───────────────────────────────────────────────────────────

    /**
     * Perform a client-side redirect. The browser navigates without a full reload.
     * Use after POST operations (PRG pattern).
     *
     * @param url absolute or relative URL
     */
    public static void redirect(HttpServletResponse response, String url) {
        response.setHeader("HX-Redirect", url);
    }

    /**
     * Force a full page refresh (equivalent to window.location.reload()).
     */
    public static void refresh(HttpServletResponse response) {
        response.setHeader("HX-Refresh", "true");
    }

    /**
     * Push a new URL into the browser history without navigating.
     * Useful for updating the address bar during HTMX partial swaps.
     *
     * @param url the URL to push, e.g. "/catalog/fasteners?page=2"
     */
    public static void pushUrl(HttpServletResponse response, String url) {
        response.setHeader("HX-Push-Url", url);
    }

    /**
     * Replace the current URL in history (no new history entry).
     */
    public static void replaceUrl(HttpServletResponse response, String url) {
        response.setHeader("HX-Replace-Url", url);
    }

    // ─── Swap control ─────────────────────────────────────────────────────────

    /**
     * Override the target element for the swap.
     * Useful when a form error should redirect the swap to an error container.
     *
     * @param cssSelector e.g. "#error-banner", ".product-grid"
     */
    public static void retarget(HttpServletResponse response, String cssSelector) {
        response.setHeader("HX-Retarget", cssSelector);
    }

    /**
     * Override the swap strategy.
     *
     * @param swapStrategy e.g. "innerHTML", "outerHTML", "afterend", "none"
     */
    public static void reswap(HttpServletResponse response, String swapStrategy) {
        response.setHeader("HX-Reswap", swapStrategy);
    }

    // ─── Misc ─────────────────────────────────────────────────────────────────

    /**
     * Returns true if the incoming request was made by HTMX.
     * Use to return full page vs fragment depending on the caller.
     *
     * <pre>{@code
     * if (HtmxResponse.isHtmxRequest(request)) {
     *     return "catalog/product-grid :: grid";   // fragment
     * }
     * return "catalog/product-list";               // full page
     * }</pre>
     */
    public static boolean isHtmxRequest(jakarta.servlet.http.HttpServletRequest request) {
        return "true".equals(request.getHeader("HX-Request"));
    }

    /**
     * Returns the value of HX-Current-URL if present.
     * Useful for knowing which page triggered a partial request.
     */
    public static String currentUrl(jakarta.servlet.http.HttpServletRequest request) {
        return request.getHeader("HX-Current-URL");
    }
}
