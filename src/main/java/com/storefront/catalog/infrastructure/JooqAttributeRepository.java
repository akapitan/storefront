package com.storefront.catalog.infrastructure;

import com.storefront.catalog.CatalogApi.AttributeSummary;
import com.storefront.catalog.CatalogApi.ColumnConfig;
import com.storefront.catalog.CatalogApi.FacetGroup;
import com.storefront.catalog.CatalogApi.FacetOption;
import com.storefront.catalog.domain.model.AttributeRepository;
import org.jooq.DSLContext;
import org.jooq.impl.DSL;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.UUID;

import static com.storefront.jooq.Tables.ATTRIBUTE_DEFINITIONS;
import static com.storefront.jooq.Tables.ATTRIBUTE_OPTIONS;
import static com.storefront.jooq.Tables.PRODUCT_GROUP_COLUMNS;
import static com.storefront.jooq.Tables.SKUS;
import static com.storefront.jooq.Tables.SKU_ATTRIBUTES;

@Repository
class JooqAttributeRepository implements AttributeRepository {

    private final DSLContext readOnlyDsl;

    JooqAttributeRepository(@Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.readOnlyDsl = readOnlyDsl;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ColumnConfig> findColumnConfig(UUID groupId) {
        return readOnlyDsl
                .select(
                        PRODUCT_GROUP_COLUMNS.SORT_ORDER,
                        PRODUCT_GROUP_COLUMNS.ROLE,
                        DSL.coalesce(PRODUCT_GROUP_COLUMNS.COLUMN_HEADER, ATTRIBUTE_DEFINITIONS.LABEL).as("header"),
                        DSL.coalesce(PRODUCT_GROUP_COLUMNS.COLUMN_WIDTH_PX, ATTRIBUTE_DEFINITIONS.TABLE_COLUMN_WIDTH).as("width"),
                        ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                        ATTRIBUTE_DEFINITIONS.DATA_TYPE,
                        ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER,
                        ATTRIBUTE_DEFINITIONS.IS_FILTERABLE
                )
                .from(PRODUCT_GROUP_COLUMNS)
                .join(ATTRIBUTE_DEFINITIONS).on(ATTRIBUTE_DEFINITIONS.ID.eq(PRODUCT_GROUP_COLUMNS.ATTRIBUTE_ID))
                .where(PRODUCT_GROUP_COLUMNS.PRODUCT_GROUP_ID.eq(groupId))
                .orderBy(PRODUCT_GROUP_COLUMNS.SORT_ORDER)
                .fetch(r -> new ColumnConfig(
                        r.get(PRODUCT_GROUP_COLUMNS.SORT_ORDER),
                        r.get(PRODUCT_GROUP_COLUMNS.ROLE),
                        r.get("header", String.class),
                        r.get("width", Integer.class),
                        r.get(ATTRIBUTE_DEFINITIONS.KEY),
                        r.get(ATTRIBUTE_DEFINITIONS.UNIT_LABEL),
                        r.get(ATTRIBUTE_DEFINITIONS.DATA_TYPE),
                        r.get(ATTRIBUTE_DEFINITIONS.FILTER_WIDGET),
                        r.get(ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER),
                        r.get(ATTRIBUTE_DEFINITIONS.IS_FILTERABLE)
                ));
    }

    @Override
    @Transactional(readOnly = true)
    public List<FacetGroup> findFacetCounts(UUID groupId, List<UUID> matchingSkuIds) {
        var records = readOnlyDsl
                .select(
                        ATTRIBUTE_DEFINITIONS.ID,
                        ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL,
                        ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                        ATTRIBUTE_OPTIONS.ID.as("option_id"),
                        ATTRIBUTE_OPTIONS.VALUE,
                        ATTRIBUTE_OPTIONS.DISPLAY_VALUE,
                        DSL.count(SKU_ATTRIBUTES.SKU_ID).as("sku_count")
                )
                .from(ATTRIBUTE_DEFINITIONS)
                .join(PRODUCT_GROUP_COLUMNS).on(
                        PRODUCT_GROUP_COLUMNS.ATTRIBUTE_ID.eq(ATTRIBUTE_DEFINITIONS.ID)
                                .and(PRODUCT_GROUP_COLUMNS.PRODUCT_GROUP_ID.eq(groupId))
                                .and(ATTRIBUTE_DEFINITIONS.IS_FILTERABLE.isTrue()))
                .join(SKU_ATTRIBUTES).on(SKU_ATTRIBUTES.ATTRIBUTE_ID.eq(ATTRIBUTE_DEFINITIONS.ID))
                .join(SKUS).on(SKUS.ID.eq(SKU_ATTRIBUTES.SKU_ID)
                        .and(SKUS.PRODUCT_GROUP_ID.eq(groupId))
                        .and(SKUS.IS_ACTIVE.isTrue())
                        .and(matchingSkuIds != null && !matchingSkuIds.isEmpty()
                                ? SKUS.ID.in(matchingSkuIds)
                                : DSL.trueCondition()))
                .leftJoin(ATTRIBUTE_OPTIONS).on(ATTRIBUTE_OPTIONS.ID.eq(SKU_ATTRIBUTES.OPTION_ID))
                .groupBy(ATTRIBUTE_DEFINITIONS.ID, ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL, ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                        ATTRIBUTE_OPTIONS.ID, ATTRIBUTE_OPTIONS.VALUE,
                        ATTRIBUTE_OPTIONS.DISPLAY_VALUE, ATTRIBUTE_OPTIONS.SORT_ORDER,
                        PRODUCT_GROUP_COLUMNS.SORT_ORDER)
                .orderBy(PRODUCT_GROUP_COLUMNS.SORT_ORDER, ATTRIBUTE_OPTIONS.SORT_ORDER)
                .fetch();

        // Group by attribute
        LinkedHashMap<Integer, FacetGroup> groups = new LinkedHashMap<>();
        for (var r : records) {
            int attrId = r.get(ATTRIBUTE_DEFINITIONS.ID);
            groups.computeIfAbsent(attrId, id -> new FacetGroup(
                    id,
                    r.get(ATTRIBUTE_DEFINITIONS.KEY),
                    r.get(ATTRIBUTE_DEFINITIONS.LABEL),
                    r.get(ATTRIBUTE_DEFINITIONS.FILTER_WIDGET),
                    r.get(ATTRIBUTE_DEFINITIONS.UNIT_LABEL),
                    new ArrayList<>()
            ));

            Integer optionId = r.get("option_id", Integer.class);
            groups.get(attrId).options().add(new FacetOption(
                    optionId,
                    r.get(ATTRIBUTE_OPTIONS.VALUE),
                    r.get(ATTRIBUTE_OPTIONS.DISPLAY_VALUE),
                    r.get("sku_count", Integer.class)
            ));
        }

        return new ArrayList<>(groups.values());
    }

    @Override
    @Transactional(readOnly = true)
    public List<AttributeSummary> findFilterableAttributes(int categoryId) {
        return readOnlyDsl
                .select(ATTRIBUTE_DEFINITIONS.ID,
                        ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL,
                        ATTRIBUTE_DEFINITIONS.DATA_TYPE,
                        ATTRIBUTE_DEFINITIONS.FILTER_WIDGET)
                .from(ATTRIBUTE_DEFINITIONS)
                .where(ATTRIBUTE_DEFINITIONS.CATEGORY_ID.eq(categoryId)
                        .and(ATTRIBUTE_DEFINITIONS.IS_FILTERABLE.isTrue()))
                .orderBy(ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER)
                .fetch(r -> new AttributeSummary(
                        r.get(ATTRIBUTE_DEFINITIONS.ID),
                        r.get(ATTRIBUTE_DEFINITIONS.KEY),
                        r.get(ATTRIBUTE_DEFINITIONS.LABEL),
                        r.get(ATTRIBUTE_DEFINITIONS.DATA_TYPE),
                        r.get(ATTRIBUTE_DEFINITIONS.FILTER_WIDGET)
                ));
    }
}
