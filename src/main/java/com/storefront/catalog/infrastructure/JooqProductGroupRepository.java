package com.storefront.catalog.infrastructure;

import com.storefront.catalog.CatalogApi.ProductGroupDetail;
import com.storefront.catalog.CatalogApi.ProductGroupSummary;
import com.storefront.catalog.domain.model.ProductGroupRepository;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Pagination;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;
import org.jooq.DSLContext;
import org.jooq.Record;
import org.jooq.impl.DSL;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

import static com.storefront.jooq.Tables.CATEGORIES;
import static com.storefront.jooq.Tables.PRODUCT_GROUPS;

@Repository
class JooqProductGroupRepository implements ProductGroupRepository {

    private final DSLContext readOnlyDsl;

    JooqProductGroupRepository(@Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.readOnlyDsl = readOnlyDsl;
    }

    @Override
    @Cacheable(value = "product-listing", cacheManager = "redisCacheManager",
            key = "'browse:' + #categoryPath + ':' + #request.page() + ':' + #request.pageSize()")
    @Transactional(readOnly = true)
    public Slice<ProductGroupSummary> browseByCategory(String categoryPath, SliceRequest request) {
        List<ProductGroupSummary> rows = readOnlyDsl
                .select(PRODUCT_GROUPS.ID, PRODUCT_GROUPS.NAME, PRODUCT_GROUPS.SUBTITLE,
                        PRODUCT_GROUPS.SLUG, PRODUCT_GROUPS.OVERVIEW_IMAGE_URL,
                        PRODUCT_GROUPS.SKU_COUNT, PRODUCT_GROUPS.MIN_PRICE_USD,
                        PRODUCT_GROUPS.ANY_IN_STOCK)
                .from(PRODUCT_GROUPS)
                .join(CATEGORIES).on(CATEGORIES.ID.eq(PRODUCT_GROUPS.CATEGORY_ID))
                .where(DSL.condition("{0} <@ {1}::ltree",
                                DSL.field("categories.path", Object.class),
                                DSL.val(categoryPath))
                        .and(PRODUCT_GROUPS.IS_ACTIVE.isTrue()))
                .orderBy(PRODUCT_GROUPS.SORT_ORDER, PRODUCT_GROUPS.NAME)
                .limit(request.fetchSize())
                .offset(request.offset())
                .fetch(this::toSummary);

        return Slice.of(rows, request);
    }

    @Override
    @Cacheable(value = "product-detail", cacheManager = "redisCacheManager", key = "'group:' + #slug")
    @Transactional(readOnly = true)
    public Optional<ProductGroupDetail> findBySlug(String slug) {
        return readOnlyDsl
                .select(PRODUCT_GROUPS.ID, PRODUCT_GROUPS.NAME, PRODUCT_GROUPS.SUBTITLE,
                        PRODUCT_GROUPS.SLUG, PRODUCT_GROUPS.DESCRIPTION,
                        PRODUCT_GROUPS.ENGINEERING_NOTE, PRODUCT_GROUPS.OVERVIEW_IMAGE_URL,
                        PRODUCT_GROUPS.DIAGRAM_IMAGE_URL, PRODUCT_GROUPS.SKU_COUNT,
                        PRODUCT_GROUPS.MIN_PRICE_USD, PRODUCT_GROUPS.ANY_IN_STOCK,
                        CATEGORIES.ID.as("categoryId"),
                        CATEGORIES.NAME.as("categoryName"),
                        CATEGORIES.PATH.as("categoryPath"))
                .from(PRODUCT_GROUPS)
                .join(CATEGORIES).on(CATEGORIES.ID.eq(PRODUCT_GROUPS.CATEGORY_ID))
                .where(PRODUCT_GROUPS.SLUG.eq(slug).and(PRODUCT_GROUPS.IS_ACTIVE.isTrue()))
                .fetchOptional(r -> new ProductGroupDetail(
                        r.get(PRODUCT_GROUPS.ID),
                        r.get(PRODUCT_GROUPS.NAME),
                        r.get(PRODUCT_GROUPS.SUBTITLE),
                        r.get(PRODUCT_GROUPS.SLUG),
                        r.get(PRODUCT_GROUPS.DESCRIPTION),
                        r.get(PRODUCT_GROUPS.ENGINEERING_NOTE),
                        r.get(PRODUCT_GROUPS.OVERVIEW_IMAGE_URL),
                        r.get(PRODUCT_GROUPS.DIAGRAM_IMAGE_URL),
                        r.get(PRODUCT_GROUPS.SKU_COUNT),
                        r.get(PRODUCT_GROUPS.MIN_PRICE_USD),
                        r.get(PRODUCT_GROUPS.ANY_IN_STOCK),
                        r.get("categoryId", Integer.class),
                        r.get("categoryName", String.class),
                        String.valueOf(r.get("categoryPath"))
                ));
    }

    @Override
    @Cacheable(value = "search-results", cacheManager = "redisCacheManager",
            key = "'search:' + #query + ':' + #request.page() + ':' + #request.pageSize()")
    @Transactional(readOnly = true)
    public Pagination<ProductGroupSummary> search(String query, PageRequest request) {
        var tsQuery = DSL.field("websearch_to_tsquery('english', {0})", Object.class, query);
        var searchVec = DSL.field("search_vector", Object.class);
        var rank = DSL.field("ts_rank(search_vector, websearch_to_tsquery('english', {0}))", Double.class, query);

        var condition = DSL.condition("{0} @@ {1}", searchVec, tsQuery)
                .and(PRODUCT_GROUPS.IS_ACTIVE.isTrue());

        var trigramCondition = DSL.condition("{0} % {1}", PRODUCT_GROUPS.NAME, DSL.val(query))
                .and(PRODUCT_GROUPS.IS_ACTIVE.isTrue());

        var combinedCondition = condition.or(trigramCondition);

        int total = readOnlyDsl.selectCount().from(PRODUCT_GROUPS)
                .where(combinedCondition).fetchOne(0, int.class);

        List<ProductGroupSummary> items = readOnlyDsl
                .select(PRODUCT_GROUPS.ID, PRODUCT_GROUPS.NAME, PRODUCT_GROUPS.SUBTITLE,
                        PRODUCT_GROUPS.SLUG, PRODUCT_GROUPS.OVERVIEW_IMAGE_URL,
                        PRODUCT_GROUPS.SKU_COUNT, PRODUCT_GROUPS.MIN_PRICE_USD,
                        PRODUCT_GROUPS.ANY_IN_STOCK)
                .from(PRODUCT_GROUPS)
                .where(combinedCondition)
                .orderBy(rank.desc())
                .limit(request.pageSize())
                .offset(request.offset())
                .fetch(this::toSummary);

        return Pagination.of(items, total, request);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductGroupSummary> searchDropdown(String query, int limit) {
        var tsQuery = DSL.field("websearch_to_tsquery('english', {0})", Object.class, query);
        var searchVec = DSL.field("search_vector", Object.class);
        var rank = DSL.field("ts_rank(search_vector, websearch_to_tsquery('english', {0}))", Double.class, query);

        var condition = DSL.condition("{0} @@ {1}", searchVec, tsQuery)
                .and(PRODUCT_GROUPS.IS_ACTIVE.isTrue());

        var trigramCondition = DSL.condition("{0} % {1}", PRODUCT_GROUPS.NAME, DSL.val(query))
                .and(PRODUCT_GROUPS.IS_ACTIVE.isTrue());

        return readOnlyDsl
                .select(PRODUCT_GROUPS.ID, PRODUCT_GROUPS.NAME, PRODUCT_GROUPS.SUBTITLE,
                        PRODUCT_GROUPS.SLUG, PRODUCT_GROUPS.OVERVIEW_IMAGE_URL,
                        PRODUCT_GROUPS.SKU_COUNT, PRODUCT_GROUPS.MIN_PRICE_USD,
                        PRODUCT_GROUPS.ANY_IN_STOCK)
                .from(PRODUCT_GROUPS)
                .where(condition.or(trigramCondition))
                .orderBy(rank.desc())
                .limit(limit)
                .fetch(this::toSummary);
    }

    private ProductGroupSummary toSummary(Record r) {
        return new ProductGroupSummary(
                r.get(PRODUCT_GROUPS.ID),
                r.get(PRODUCT_GROUPS.NAME),
                r.get(PRODUCT_GROUPS.SUBTITLE),
                r.get(PRODUCT_GROUPS.SLUG),
                r.get(PRODUCT_GROUPS.OVERVIEW_IMAGE_URL),
                r.get(PRODUCT_GROUPS.SKU_COUNT),
                r.get(PRODUCT_GROUPS.MIN_PRICE_USD),
                r.get(PRODUCT_GROUPS.ANY_IN_STOCK)
        );
    }
}
