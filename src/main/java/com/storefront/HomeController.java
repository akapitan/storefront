package com.storefront;

import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * HomeController — serves the landing page at root (/).
 *
 * Displays McMaster-style category grid and optional featured products.
 * This is the entry point for users visiting the site.
 *
 * When an HTMX request is made, returns only the "home-content" fragment,
 * allowing the page to act as a single-page application without full reloads.
 */
@Controller
class HomeController {

    /**
     * Landing page — McMaster-style category grid.
     * HTMX requests get only the home-content fragment.
     * Direct browser loads get the full page with layout.
     */
    @GetMapping("/")
    public String home(HttpServletRequest request) {
        if (HtmxResponse.isHtmxRequest(request)) {
            return "index :: home-content";
        }
        return "index";
    }
}


