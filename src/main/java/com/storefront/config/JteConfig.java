package com.storefront.config;

import gg.jte.ContentType;
import gg.jte.TemplateEngine;
import gg.jte.resolve.DirectoryCodeResolver;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.nio.file.Path;

/**
 * JTE (Java Template Engine) Configuration.
 * <p>
 * Configures JTE for server-side rendering with HTMX-based SPA patterns.
 * Templates are compiled for type safety and performance.
 */
@Configuration
class JteConfig {

    /**
     * Configure JTE TemplateEngine.
     * <p>
     * In development: templates are reloaded on change
     * In production: templates are precompiled for performance
     */
    @Bean
    public TemplateEngine templateEngine() {
        // Development mode: hot reload from src/main/resources/templates/jte
        if (isDevelopment()) {
            Path templatePath = Path.of("src/main/resources/templates/jte");
            DirectoryCodeResolver codeResolver = new DirectoryCodeResolver(templatePath);
            return TemplateEngine.create(codeResolver, ContentType.Html);
        }

        // Production mode: use precompiled templates from classpath
        return TemplateEngine.createPrecompiled(ContentType.Html);
    }

    private boolean isDevelopment() {
        String profile = System.getProperty("spring.profiles.active", "");
        return profile.contains("dev") || profile.isEmpty();
    }
}

