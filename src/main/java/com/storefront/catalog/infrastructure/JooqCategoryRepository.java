package com.storefront.catalog.infrastructure;

import com.storefront.catalog.CatalogApi.CategoryBreadcrumb;
import com.storefront.catalog.CatalogApi.CategoryNode;
import com.storefront.catalog.domain.model.CategoryRepository;
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

@Repository
class JooqCategoryRepository implements CategoryRepository {

    private final DSLContext readOnlyDsl;

    JooqCategoryRepository(@Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.readOnlyDsl = readOnlyDsl;
    }

    @Override
    @Cacheable(value = "categories", key = "'top-level'")
    @Transactional(readOnly = true)
    public List<CategoryNode> findTopLevel() {
        return readOnlyDsl
                .select(CATEGORIES.ID, CATEGORIES.NAME, CATEGORIES.SLUG,
                        CATEGORIES.PATH, CATEGORIES.GROUP_COUNT,
                        CATEGORIES.IS_LEAF, CATEGORIES.SORT_ORDER)
                .from(CATEGORIES)
                .where(CATEGORIES.DEPTH.eq((short) 0).and(CATEGORIES.IS_ACTIVE.isTrue()))
                .orderBy(CATEGORIES.SORT_ORDER)
                .fetch(this::toNode);
    }

    @Override
    @Cacheable(value = "categories", key = "'children:' + #parentId")
    @Transactional(readOnly = true)
    public List<CategoryNode> findChildren(int parentId) {
        return readOnlyDsl
                .select(CATEGORIES.ID, CATEGORIES.NAME, CATEGORIES.SLUG,
                        CATEGORIES.PATH, CATEGORIES.GROUP_COUNT,
                        CATEGORIES.IS_LEAF, CATEGORIES.SORT_ORDER)
                .from(CATEGORIES)
                .where(CATEGORIES.PARENT_ID.eq(parentId).and(CATEGORIES.IS_ACTIVE.isTrue()))
                .orderBy(CATEGORIES.SORT_ORDER)
                .fetch(this::toNode);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategoryBreadcrumb> findBreadcrumb(String categoryPath) {
        return readOnlyDsl
                .select(CATEGORIES.ID, CATEGORIES.NAME, CATEGORIES.SLUG)
                .from(CATEGORIES)
                .where(DSL.condition("{0} @> {1}::ltree",
                        DSL.field("path", Object.class),
                        DSL.val(categoryPath)))
                .orderBy(CATEGORIES.DEPTH)
                .fetch(r -> new CategoryBreadcrumb(
                        r.get(CATEGORIES.ID),
                        r.get(CATEGORIES.NAME),
                        r.get(CATEGORIES.SLUG)
                ));
    }

    @Override
    @Cacheable(value = "categories", key = "'slug:' + #slug")
    @Transactional(readOnly = true)
    public Optional<CategoryNode> findBySlug(String slug) {
        return readOnlyDsl
                .select(CATEGORIES.ID, CATEGORIES.NAME, CATEGORIES.SLUG,
                        CATEGORIES.PATH, CATEGORIES.GROUP_COUNT,
                        CATEGORIES.IS_LEAF, CATEGORIES.SORT_ORDER)
                .from(CATEGORIES)
                .where(CATEGORIES.SLUG.eq(slug).and(CATEGORIES.IS_ACTIVE.isTrue()))
                .fetchOptional(this::toNode);
    }

    private CategoryNode toNode(Record r) {
        return new CategoryNode(
                r.get(CATEGORIES.ID),
                r.get(CATEGORIES.NAME),
                r.get(CATEGORIES.SLUG),
                String.valueOf(r.get(CATEGORIES.PATH)),
                r.get(CATEGORIES.GROUP_COUNT),
                r.get(CATEGORIES.IS_LEAF),
                r.get(CATEGORIES.SORT_ORDER)
        );
    }
}
