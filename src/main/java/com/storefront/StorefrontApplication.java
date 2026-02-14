package com.storefront;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * StorefrontApplication — single deployable Spring Boot modulith.
 * Modules:
 *   com.storefront.catalog   — products, categories (public: CatalogApi)
 *   com.storefront.inventory — stock, warehouse   (public: InventoryApi)
 *   com.storefront.shared    — shared kernel       (visible to all modules)
 *   com.storefront.config    — cross-cutting infra
 * Run locally:
 *   ./gradlew bootRunDev
 * Run with Docker Compose (Postgres + Redis):
 *   docker compose up -d
 *   ./gradlew bootRunDev
 */
@SpringBootApplication
@EnableCaching
@EnableAsync
public final class StorefrontApplication {

    private StorefrontApplication() {
    }

    public static void main(String[] args) {
        SpringApplication.run(StorefrontApplication.class, args);
    }
}
