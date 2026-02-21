package com.storefront;

import com.storefront.catalog.CategoryApi;
import com.storefront.shared.web.HtmxResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
@RequiredArgsConstructor
class HomeController {

    private final CategoryApi categoryApi;

    @GetMapping("/")
    public String home(HttpServletRequest request, Model model) {
        var sections = categoryApi.findAllCategoriesGrouped();
        model.addAttribute("sections", sections);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "home/content-with-sidebar";
        }
        return "home/page";
    }
}
