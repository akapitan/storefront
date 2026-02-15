package com.storefront;

import com.storefront.catalog.CatalogApi;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

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
}
