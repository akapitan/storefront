package com.storefront.shared.web;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

/**
 * Template helper utilities for JTE templates.
 *
 * Provides formatting and utility methods that would otherwise
 * be done by template expression utilities (like Thymeleaf's #numbers).
 */
@Component("fmt")
public final class TemplateHelpers {

    private TemplateHelpers() {
        // Spring will instantiate via reflection
    }

    /**
     * Format a BigDecimal as USD currency.
     * Example: 29.99 → "$29.99"
     */
    public static String formatCurrency(BigDecimal amount) {
        if (amount == null) {
            return "$0.00";
        }
        return NumberFormat.getCurrencyInstance(Locale.US).format(amount);
    }

    /**
     * Check if a string is null or empty.
     */
    public static boolean isEmpty(String value) {
        return value == null || value.isEmpty();
    }

    /**
     * Check if a string is not null and not empty.
     */
    public static boolean isNotEmpty(String value) {
        return !isEmpty(value);
    }

    /**
     * Safe string concatenation for CSS classes.
     */
    public static String classNames(String... classes) {
        return String.join(" ", classes);
    }

    /**
     * Conditional CSS class.
     */
    public static String classIf(boolean condition, String className) {
        return condition ? className : "";
    }

    /**
     * Conditional CSS class with fallback.
     */
    public static String classIf(boolean condition, String ifTrue, String ifFalse) {
        return condition ? ifTrue : ifFalse;
    }
}

