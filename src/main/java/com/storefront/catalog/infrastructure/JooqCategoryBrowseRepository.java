package com.storefront.catalog.infrastructure;

import com.storefront.catalog.CategoryApi.FilteredCategory;
import com.storefront.catalog.ProductApi.FacetGroup;
import com.storefront.catalog.ProductApi.FacetOption;
import com.storefront.catalog.ProductApi.NumericRange;
import com.storefront.catalog.domain.model.CategoryBrowseRepository;
import org.jooq.Condition;
import org.jooq.DSLContext;
import org.jooq.impl.DSL;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

import static com.storefront.jooq.Tables.*;

@Repository
class JooqCategoryBrowseRepository implements CategoryBrowseRepository {

    private final DSLContext dsl;

    JooqCategoryBrowseRepository(@Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.dsl = readOnlyDsl;
    }

    // ─── Mid-level: filtered children ────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<FilteredCategory> findFilteredChildren(
            int parentId, String parentPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {

        var sfi = SKU_FACET_INDEX.as("sfi");
        var cLeaf = CATEGORIES.as("c_leaf");
        var cChild = CATEGORIES.as("c_child");

        Condition skuCondition = buildSkuFilterCondition(sfi, enumFilters, rangeFilters);

        return dsl
                .select(
                        cChild.ID,
                        cChild.NAME,
                        cChild.SLUG,
                        cChild.PATH,
                        cChild.IS_LEAF,
                        cChild.DEPTH,
                        cChild.SORT_ORDER,
                        DSL.countDistinct(sfi.SKU_ID).as("sku_count"))
                .from(cChild)
                .join(cLeaf).on(DSL.condition("{0} <@ {1}::ltree",
                        cLeaf.PATH, cChild.PATH)
                        .and(cLeaf.IS_LEAF.isTrue())
                        .and(cLeaf.IS_ACTIVE.isTrue()))
                .join(sfi).on(sfi.CATEGORY_ID.eq(cLeaf.ID))
                .where(cChild.PARENT_ID.eq(parentId)
                        .and(cChild.IS_ACTIVE.isTrue())
                        .and(skuCondition))
                .groupBy(cChild.ID, cChild.NAME, cChild.SLUG,
                        cChild.PATH, cChild.IS_LEAF,
                        cChild.DEPTH, cChild.SORT_ORDER)
                .having(DSL.countDistinct(sfi.SKU_ID).gt(0))
                .orderBy(cChild.SORT_ORDER)
                .fetch(r -> new FilteredCategory(
                        r.get(cChild.ID),
                        r.get(cChild.NAME),
                        r.get(cChild.SLUG),
                        String.valueOf(r.get(cChild.PATH)),
                        r.get(cChild.IS_LEAF),
                        r.get(cChild.DEPTH),
                        r.get(cChild.SORT_ORDER),
                        r.get("sku_count", Long.class)));
    }

    // ─── Mid-level: facets across descendants ─────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<FacetGroup> findMidLevelFacets(
            String categoryPath,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {

        var sfi = SKU_FACET_INDEX.as("sfi");
        var cLeaf = CATEGORIES.as("c_leaf");

        Condition skuCondition = buildSkuFilterCondition(sfi, enumFilters, rangeFilters);

        var records = dsl
                .select(
                        ATTRIBUTE_DEFINITIONS.ID,
                        ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL,
                        ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                        ATTRIBUTE_OPTIONS.ID.as("option_id"),
                        ATTRIBUTE_OPTIONS.VALUE,
                        ATTRIBUTE_OPTIONS.DISPLAY_VALUE,
                        ATTRIBUTE_OPTIONS.IMAGE_URL,
                        DSL.countDistinct(sfi.SKU_ID).as("sku_count"))
                .from(cLeaf)
                .join(sfi).on(sfi.CATEGORY_ID.eq(cLeaf.ID))
                .join(ATTRIBUTE_DEFINITIONS).on(ATTRIBUTE_DEFINITIONS.ID.eq(sfi.ATTRIBUTE_ID)
                        .and(ATTRIBUTE_DEFINITIONS.IS_FILTERABLE.isTrue()))
                .leftJoin(ATTRIBUTE_OPTIONS).on(ATTRIBUTE_OPTIONS.ID.eq(sfi.OPTION_ID))
                .where(DSL.condition("{0} <@ {1}::ltree",
                        cLeaf.PATH, DSL.val(categoryPath))
                        .and(cLeaf.IS_LEAF.isTrue())
                        .and(cLeaf.IS_ACTIVE.isTrue())
                        .and(skuCondition))
                .groupBy(ATTRIBUTE_DEFINITIONS.ID, ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL, ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL, ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER,
                        ATTRIBUTE_OPTIONS.ID, ATTRIBUTE_OPTIONS.VALUE,
                        ATTRIBUTE_OPTIONS.DISPLAY_VALUE, ATTRIBUTE_OPTIONS.IMAGE_URL,
                        ATTRIBUTE_OPTIONS.SORT_ORDER)
                .having(DSL.countDistinct(sfi.SKU_ID).gt(0))
                .orderBy(ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER, ATTRIBUTE_OPTIONS.SORT_ORDER)
                .fetch();

        return toFacetGroups(records,
                ATTRIBUTE_DEFINITIONS.ID, ATTRIBUTE_DEFINITIONS.KEY,
                ATTRIBUTE_DEFINITIONS.LABEL, ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                ATTRIBUTE_OPTIONS.VALUE, ATTRIBUTE_OPTIONS.DISPLAY_VALUE,
                ATTRIBUTE_OPTIONS.IMAGE_URL);
    }

    // ─── Leaf: category-level facets ─────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<FacetGroup> findLeafFacets(
            int categoryId,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {

        var sfi = SKU_FACET_INDEX.as("sfi");

        Condition skuCondition = buildSkuFilterCondition(sfi, enumFilters, rangeFilters);

        var records = dsl
                .select(
                        ATTRIBUTE_DEFINITIONS.ID,
                        ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL,
                        ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                        ATTRIBUTE_OPTIONS.ID.as("option_id"),
                        ATTRIBUTE_OPTIONS.VALUE,
                        ATTRIBUTE_OPTIONS.DISPLAY_VALUE,
                        ATTRIBUTE_OPTIONS.IMAGE_URL,
                        DSL.countDistinct(sfi.SKU_ID).as("sku_count"))
                .from(sfi)
                .join(ATTRIBUTE_DEFINITIONS).on(ATTRIBUTE_DEFINITIONS.ID.eq(sfi.ATTRIBUTE_ID)
                        .and(ATTRIBUTE_DEFINITIONS.IS_FILTERABLE.isTrue()))
                .leftJoin(ATTRIBUTE_OPTIONS).on(ATTRIBUTE_OPTIONS.ID.eq(sfi.OPTION_ID))
                .where(sfi.CATEGORY_ID.eq(categoryId).and(skuCondition))
                .groupBy(ATTRIBUTE_DEFINITIONS.ID, ATTRIBUTE_DEFINITIONS.KEY,
                        ATTRIBUTE_DEFINITIONS.LABEL, ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                        ATTRIBUTE_DEFINITIONS.UNIT_LABEL, ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER,
                        ATTRIBUTE_OPTIONS.ID, ATTRIBUTE_OPTIONS.VALUE,
                        ATTRIBUTE_OPTIONS.DISPLAY_VALUE, ATTRIBUTE_OPTIONS.IMAGE_URL,
                        ATTRIBUTE_OPTIONS.SORT_ORDER)
                .having(DSL.countDistinct(sfi.SKU_ID).gt(0))
                .orderBy(ATTRIBUTE_DEFINITIONS.FILTER_SORT_ORDER, ATTRIBUTE_OPTIONS.SORT_ORDER)
                .fetch();

        return toFacetGroups(records,
                ATTRIBUTE_DEFINITIONS.ID, ATTRIBUTE_DEFINITIONS.KEY,
                ATTRIBUTE_DEFINITIONS.LABEL, ATTRIBUTE_DEFINITIONS.FILTER_WIDGET,
                ATTRIBUTE_DEFINITIONS.UNIT_LABEL,
                ATTRIBUTE_OPTIONS.VALUE, ATTRIBUTE_OPTIONS.DISPLAY_VALUE,
                ATTRIBUTE_OPTIONS.IMAGE_URL);
    }

    // ─── Leaf: matching SKU IDs by product group ──────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Map<UUID, List<UUID>> findMatchingSkuIdsByGroup(
            int categoryId,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {

        var sfi = SKU_FACET_INDEX.as("sfi");

        Condition skuCondition = buildSkuFilterCondition(sfi, enumFilters, rangeFilters);

        var rows = dsl
                .selectDistinct(sfi.PRODUCT_GROUP_ID, sfi.SKU_ID)
                .from(sfi)
                .where(sfi.CATEGORY_ID.eq(categoryId).and(skuCondition))
                .fetch();

        Map<UUID, List<UUID>> result = new LinkedHashMap<>();
        for (var r : rows) {
            result.computeIfAbsent(r.get(sfi.PRODUCT_GROUP_ID), k -> new ArrayList<>())
                    .add(r.get(sfi.SKU_ID));
        }
        return result;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private Condition buildSkuFilterCondition(
            org.jooq.Table<?> sfiAlias,
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters) {

        if ((enumFilters == null || enumFilters.isEmpty()) &&
                (rangeFilters == null || rangeFilters.isEmpty())) {
            return DSL.trueCondition();
        }

        var inner = SKU_FACET_INDEX.as("sfi_inner");
        var outerSkuId = DSL.field(DSL.name(sfiAlias.getName(), "sku_id"), java.util.UUID.class);

        Condition combined = DSL.trueCondition();

        if (enumFilters != null) {
            for (var entry : enumFilters.entrySet()) {
                int attrId = entry.getKey();
                var optionIds = entry.getValue();
                if (optionIds == null || optionIds.isEmpty()) continue;

                combined = combined.and(DSL.exists(
                        dsl.selectOne().from(inner)
                                .where(inner.SKU_ID.eq(outerSkuId)
                                        .and(inner.ATTRIBUTE_ID.eq(attrId))
                                        .and(inner.OPTION_ID.in(optionIds)))
                ));
            }
        }

        if (rangeFilters != null) {
            for (var entry : rangeFilters.entrySet()) {
                int attrId = entry.getKey();
                var range = entry.getValue();
                if (range == null) continue;

                combined = combined.and(DSL.exists(
                        dsl.selectOne().from(inner)
                                .where(inner.SKU_ID.eq(outerSkuId)
                                        .and(inner.ATTRIBUTE_ID.eq(attrId))
                                        .and(inner.VALUE_NUMERIC.between(range.min(), range.max())))
                ));
            }
        }

        return combined;
    }

    private List<FacetGroup> toFacetGroups(
            org.jooq.Result<?> records,
            org.jooq.Field<Integer> attrIdField,
            org.jooq.Field<String> keyField,
            org.jooq.Field<String> labelField,
            org.jooq.Field<String> widgetField,
            org.jooq.Field<String> unitField,
            org.jooq.Field<String> valueField,
            org.jooq.Field<String> displayValueField,
            org.jooq.Field<String> imageUrlField) {

        LinkedHashMap<Integer, FacetGroup> groups = new LinkedHashMap<>();
        for (var r : records) {
            int attrId = r.get(attrIdField);
            groups.computeIfAbsent(attrId, id -> new FacetGroup(
                    id,
                    r.get(keyField),
                    r.get(labelField),
                    r.get(widgetField),
                    r.get(unitField),
                    new ArrayList<>()));

            Integer optionId = r.get("option_id", Integer.class);
            groups.get(attrId).options().add(new FacetOption(
                    optionId,
                    r.get(valueField),
                    r.get(displayValueField),
                    r.get(imageUrlField),
                    r.get("sku_count", Integer.class)));
        }
        return new ArrayList<>(groups.values());
    }
}
