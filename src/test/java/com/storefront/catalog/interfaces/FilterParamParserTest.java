package com.storefront.catalog.interfaces;

import com.storefront.catalog.ProductApi.NumericRange;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class FilterParamParserTest {

    @Test
    void parsesEnumFilters() {
        var params = Map.of("enum_3", "1,2,5", "enum_7", "9");
        var result = FilterParamParser.parse(params);

        assertThat(result.enumFilters()).containsKey(3);
        assertThat(result.enumFilters().get(3)).containsExactlyInAnyOrder(1, 2, 5);
        assertThat(result.enumFilters().get(7)).containsExactly(9);
    }

    @Test
    void parsesRangeFilters() {
        var params = Map.of("range_min_5", "1.5", "range_max_5", "10.0");
        var result = FilterParamParser.parse(params);

        assertThat(result.rangeFilters()).containsKey(5);
        var range = result.rangeFilters().get(5);
        assertThat(range.min()).isEqualByComparingTo("1.5");
        assertThat(range.max()).isEqualByComparingTo("10.0");
    }

    @Test
    void ignoresMalformedParams() {
        var params = Map.of("enum_abc", "1", "enum_3", "not,a,number", "page", "0");
        var result = FilterParamParser.parse(params);

        assertThat(result.enumFilters()).isEmpty();
    }

    @Test
    void rangeWithMissingMaxDefaultsToLargeValue() {
        var params = Map.of("range_min_5", "2.0");
        var result = FilterParamParser.parse(params);

        assertThat(result.rangeFilters().get(5).max())
                .isEqualByComparingTo("999999");
    }
}
