package com.storefront.catalog.interfaces;

import com.storefront.catalog.ProductApi.NumericRange;

import java.math.BigDecimal;
import java.util.*;

/**
 * Parses URL query parameters into typed filter maps.
 * Format: enum_{attrId}=optId1,optId2  /  range_min_{attrId}=val  range_max_{attrId}=val
 */
class FilterParamParser {

    record ParsedFilters(
            Map<Integer, List<Integer>> enumFilters,
            Map<Integer, NumericRange> rangeFilters
    ) {}

    static ParsedFilters parse(Map<String, String> params) {
        Map<Integer, List<Integer>> enumFilters = new LinkedHashMap<>();
        Map<Integer, NumericRange> rangeFilters = new LinkedHashMap<>();

        for (var entry : params.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();
            if (value == null || value.isBlank()) continue;

            if (key.startsWith("enum_")) {
                parseEnum(key.substring(5), value, enumFilters);
            } else if (key.startsWith("range_min_")) {
                parseRangeMin(key.substring(10), value, params, rangeFilters);
            }
        }
        return new ParsedFilters(enumFilters, rangeFilters);
    }

    private static void parseEnum(String attrIdStr, String value,
                                   Map<Integer, List<Integer>> out) {
        try {
            int attrId = Integer.parseInt(attrIdStr);
            List<Integer> optionIds = Arrays.stream(value.split(","))
                    .map(String::trim).filter(s -> !s.isEmpty())
                    .map(Integer::parseInt).toList();
            if (!optionIds.isEmpty()) out.put(attrId, optionIds);
        } catch (NumberFormatException ignored) {}
    }

    private static void parseRangeMin(String attrIdStr, String minVal,
                                       Map<String, String> params,
                                       Map<Integer, NumericRange> out) {
        try {
            int attrId = Integer.parseInt(attrIdStr);
            BigDecimal min = new BigDecimal(minVal);
            String maxKey = "range_max_" + attrId;
            BigDecimal max = params.containsKey(maxKey)
                    ? new BigDecimal(params.get(maxKey))
                    : new BigDecimal("999999");
            out.put(attrId, new NumericRange(min, max));
        } catch (NumberFormatException ignored) {}
    }
}
