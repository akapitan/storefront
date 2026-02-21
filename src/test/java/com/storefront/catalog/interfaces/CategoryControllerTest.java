package com.storefront.catalog.interfaces;

import com.storefront.catalog.BaseIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class CategoryControllerTest extends BaseIntegrationTest {

    @Autowired
    MockMvc mockMvc;

    @Test
    void nonExistentSlugReturns404() throws Exception {
        mockMvc.perform(get("/catalog/category/does-not-exist"))
                .andExpect(status().isNotFound());
    }
}
