package com.storefront.catalog.sku;

import com.storefront.catalog.CatalogApi.NumericRange;
import com.storefront.catalog.CatalogApi.SkuPriceInfo;
import com.storefront.catalog.CatalogApi.SkuRow;
import org.jooq.Condition;
import org.jooq.DSLContext;
import org.jooq.Record;
import org.jooq.impl.DSL;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static com.storefront.jooq.Tables.SKUS;
import static com.storefront.jooq.Tables.SKU_ATTRIBUTES;
import static com.storefront.jooq.Tables.SKU_PRICE_TIERS;

@Repository
public class SkuRepository {

    private final DSLContext readOnlyDsl;

    SkuRepository(@Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.readOnlyDsl = readOnlyDsl;
    }

    @Transactional(readOnly = true)
    public List<SkuRow> findVariantTable(UUID groupId, List<UUID> matchingSkuIds) {
        // Price tiers as JSON subquery
        var priceTiers = DSL.field(
                "(SELECT json_agg(json_build_object(" +
                        "'qty_min', pt.qty_min, 'qty_max', pt.qty_max, 'price', pt.unit_price) " +
                        "ORDER BY pt.qty_min) " +
                        "FROM sku_price_tiers pt " +
                        "WHERE pt.sku_id = skus.id AND pt.is_active AND pt.currency = 'USD')",
                String.class
        ).as("price_tiers");

        Condition condition = SKUS.PRODUCT_GROUP_ID.eq(groupId).and(SKUS.IS_ACTIVE.isTrue());
        if (matchingSkuIds != null && !matchingSkuIds.isEmpty()) {
            condition = condition.and(SKUS.ID.in(matchingSkuIds));
        }

        return readOnlyDsl
                .select(SKUS.ID, SKUS.PART_NUMBER, SKUS.SPECS_JSONB,
                        SKUS.SELL_UNIT, SKUS.SELL_QTY, SKUS.IN_STOCK,
                        SKUS.PRICE_1EA, priceTiers)
                .from(SKUS)
                .where(condition)
                .orderBy(SKUS.SORT_KEY)
                .fetch(this::toSkuRow);
    }

    @Transactional(readOnly = true)
    public List<UUID> findMatchingSkuIds(UUID groupId,
                                  Map<Integer, List<Integer>> enumFilters,
                                  Map<Integer, NumericRange> rangeFilters) {
        // Base condition: active SKUs in this product group
        Condition condition = SKUS.PRODUCT_GROUP_ID.eq(groupId).and(SKUS.IS_ACTIVE.isTrue());

        if ((enumFilters == null || enumFilters.isEmpty()) &&
                (rangeFilters == null || rangeFilters.isEmpty())) {
            return readOnlyDsl.select(SKUS.ID).from(SKUS).where(condition).fetch(SKUS.ID);
        }

        // Each filter adds an EXISTS subquery — equivalent to INTERSECT but composable
        var sa = SKU_ATTRIBUTES.as("sa");

        if (enumFilters != null) {
            for (var entry : enumFilters.entrySet()) {
                int attrId = entry.getKey();
                List<Integer> optionIds = entry.getValue();
                if (optionIds == null || optionIds.isEmpty()) continue;

                condition = condition.and(DSL.exists(
                        readOnlyDsl.selectOne()
                                .from(sa)
                                .where(sa.SKU_ID.eq(SKUS.ID)
                                        .and(sa.ATTRIBUTE_ID.eq(attrId))
                                        .and(sa.OPTION_ID.in(optionIds)))
                ));
            }
        }

        if (rangeFilters != null) {
            for (var entry : rangeFilters.entrySet()) {
                int attrId = entry.getKey();
                NumericRange range = entry.getValue();
                if (range == null) continue;

                condition = condition.and(DSL.exists(
                        readOnlyDsl.selectOne()
                                .from(sa)
                                .where(sa.SKU_ID.eq(SKUS.ID)
                                        .and(sa.ATTRIBUTE_ID.eq(attrId))
                                        .and(sa.VALUE_NUMERIC.between(range.min(), range.max())))
                ));
            }
        }

        return readOnlyDsl.select(SKUS.ID).from(SKUS).where(condition).fetch(SKUS.ID);
    }

    @Transactional(readOnly = true)
    public Optional<SkuRow> findByPartNumber(String partNumber) {
        var priceTiers = DSL.field(
                "(SELECT json_agg(json_build_object(" +
                        "'qty_min', pt.qty_min, 'qty_max', pt.qty_max, 'price', pt.unit_price) " +
                        "ORDER BY pt.qty_min) " +
                        "FROM sku_price_tiers pt " +
                        "WHERE pt.sku_id = skus.id AND pt.is_active AND pt.currency = 'USD')",
                String.class
        ).as("price_tiers");

        return readOnlyDsl
                .select(SKUS.ID, SKUS.PART_NUMBER, SKUS.SPECS_JSONB,
                        SKUS.SELL_UNIT, SKUS.SELL_QTY, SKUS.IN_STOCK,
                        SKUS.PRICE_1EA, priceTiers)
                .from(SKUS)
                .where(SKUS.PART_NUMBER.eq(partNumber).and(SKUS.IS_ACTIVE.isTrue()))
                .fetchOptional(this::toSkuRow);
    }

    @Transactional(readOnly = true)
    public boolean existsAndActive(UUID skuId) {
        return readOnlyDsl.fetchExists(
                SKUS, SKUS.ID.eq(skuId).and(SKUS.IS_ACTIVE.isTrue()));
    }

    @Transactional(readOnly = true)
    public Optional<SkuPriceInfo> findPriceInfo(UUID skuId, int quantity) {
        return readOnlyDsl
                .select(SKUS.ID, SKUS.PART_NUMBER, SKU_PRICE_TIERS.UNIT_PRICE, SKUS.SELL_UNIT)
                .from(SKUS)
                .join(SKU_PRICE_TIERS).on(SKU_PRICE_TIERS.SKU_ID.eq(SKUS.ID))
                .where(SKUS.ID.eq(skuId)
                        .and(SKUS.IS_ACTIVE.isTrue())
                        .and(SKU_PRICE_TIERS.IS_ACTIVE.isTrue())
                        .and(SKU_PRICE_TIERS.CURRENCY.eq("USD"))
                        .and(SKU_PRICE_TIERS.QTY_MIN.le(quantity))
                        .and(SKU_PRICE_TIERS.QTY_MAX.isNull().or(SKU_PRICE_TIERS.QTY_MAX.ge(quantity))))
                .orderBy(SKU_PRICE_TIERS.QTY_MIN.desc())
                .limit(1)
                .fetchOptional(r -> new SkuPriceInfo(
                        r.get(SKUS.ID),
                        r.get(SKUS.PART_NUMBER),
                        r.get(SKU_PRICE_TIERS.UNIT_PRICE),
                        r.get(SKUS.SELL_UNIT)
                ));
    }

    private SkuRow toSkuRow(Record r) {
        return new SkuRow(
                r.get(SKUS.ID),
                r.get(SKUS.PART_NUMBER),
                r.get(SKUS.SPECS_JSONB),
                r.get(SKUS.SELL_UNIT),
                r.get(SKUS.SELL_QTY),
                r.get(SKUS.IN_STOCK),
                r.get(SKUS.PRICE_1EA),
                r.get("price_tiers", String.class)
        );
    }
}
