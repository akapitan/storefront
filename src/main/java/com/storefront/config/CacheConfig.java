package com.storefront.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCache;
import org.springframework.cache.support.SimpleCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Multi-Layer Cache Configuration
 * ═════════════════════════════════
 * <p>
 * L1 — Caffeine (in-JVM, nanosecond access)
 * Best for: category tree, static config, ultra-hot product data
 * Eviction: time-based + size-based
 * Trade-off: per-instance (not shared across ECS tasks) — fine for
 * immutable/slow-changing data. Invalidate on deploy.
 * <p>
 * L2 — Redis / ElastiCache (shared across all ECS tasks, millisecond access)
 * Best for: search results, product details, user sessions, cart data
 * Eviction: TTL-based with explicit eviction on writes
 * Trade-off: network hop, but shared + survives pod restarts
 * <p>
 * Named caches and their TTLs:
 * ┌─────────────────────┬───────┬─────────┬──────────────────────────────────┐
 * │ Cache Name          │ Layer │ TTL     │ What's in it                     │
 * ├─────────────────────┼───────┼─────────┼──────────────────────────────────┤
 * │ categories          │ L1    │ 1 hour  │ Full category tree               │
 * │ product-detail      │ L2    │ 5 min   │ Single product by SKU/ID         │
 * │ product-listing     │ L2    │ 30 sec  │ Category browse pages            │
 * │ search-results      │ L2    │ 30 sec  │ Search query result sets         │
 * │ inventory           │ L2    │ 15 sec  │ Stock levels (changes often)     │
 * │ category-browse     │ L2    │ 30 sec  │ Filtered children + group tables │
 * │ category-facets     │ L2    │ 30 sec  │ Facet counts for category browse  │
 * │ user-session        │ L2    │ 30 min  │ Auth + cart state                │
 * └─────────────────────┴───────┴─────────┴──────────────────────────────────┘
 */
@Configuration(proxyBeanMethods = false)
@EnableCaching
class CacheConfig {

    private static final String CACHE_CATEGORIES = "categories";
    private static final String CACHE_PRODUCT_DETAIL_L1 = "product-detail-l1";
    private static final String CACHE_PRODUCT_DETAIL = "product-detail";
    private static final String CACHE_PRODUCT_LISTING = "product-listing";
    private static final String CACHE_SEARCH_RESULTS = "search-results";
    private static final String CACHE_INVENTORY = "inventory";
    private static final String CACHE_CATEGORY_BROWSE = "category-browse";
    private static final String CACHE_CATEGORY_FACETS = "category-facets";
    private static final String CACHE_USER_SESSION = "user-session";
    private static final String REDIS_KEY_PREFIX = "storefront:";

    // ─── L1: Caffeine (in-JVM) ────────────────────────────────────────────────

    /**
     * Primary CacheManager — Caffeine for hot, static-ish data.
     * Used when you just write @Cacheable without specifying a cacheManager.
     */
    @Bean
    @Primary
    CacheManager caffeineCacheManager() {
        var categoriesCache = new CaffeineCache(CACHE_CATEGORIES,
                Caffeine.newBuilder()
                        .maximumSize(500)
                        .expireAfterWrite(Duration.ofHours(1))
                        .recordStats()   // exposes hit/miss via Actuator
                        .build());

        // A smaller L1 for product data — acts as a "hot row" cache
        var productCache = new CaffeineCache(CACHE_PRODUCT_DETAIL_L1,
                Caffeine.newBuilder()
                        .maximumSize(2_000)
                        .expireAfterWrite(Duration.ofMinutes(2))
                        .recordStats()
                        .build());

        var manager = new SimpleCacheManager();
        manager.setCaches(List.of(categoriesCache, productCache));
        return manager;
    }

    // ─── L2: Redis ────────────────────────────────────────────────────────────

    @Bean("redisCacheManager")
    CacheManager redisCacheManager(
            RedisConnectionFactory connectionFactory) {

        // Base config — use JSON serialization (readable, debuggable in Redis CLI)
        RedisCacheConfiguration base = RedisCacheConfiguration.defaultCacheConfig()
                .serializeKeysWith(
                        RedisSerializationContext.SerializationPair
                                .fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(
                        RedisSerializationContext.SerializationPair
                                .fromSerializer(RedisSerializer.json()))
                .disableCachingNullValues()
                .prefixCacheNameWith(REDIS_KEY_PREFIX);  // namespaced keys in Redis

        // Per-cache TTL overrides
        Map<String, RedisCacheConfiguration> cacheConfigs = Map.of(
                CACHE_PRODUCT_DETAIL, base.entryTtl(Duration.ofMinutes(5)),
                CACHE_PRODUCT_LISTING, base.entryTtl(Duration.ofSeconds(30)),
                CACHE_SEARCH_RESULTS, base.entryTtl(Duration.ofSeconds(30)),
                CACHE_INVENTORY, base.entryTtl(Duration.ofSeconds(15)),
                CACHE_CATEGORY_BROWSE, base.entryTtl(Duration.ofSeconds(30)),
                CACHE_CATEGORY_FACETS, base.entryTtl(Duration.ofSeconds(30)),
                CACHE_USER_SESSION, base.entryTtl(Duration.ofMinutes(30))
        );

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(base.entryTtl(Duration.ofMinutes(1)))
                .withInitialCacheConfigurations(cacheConfigs)
                .enableStatistics()   // exposes hit/miss via Actuator /actuator/caches
                .build();
    }
}
