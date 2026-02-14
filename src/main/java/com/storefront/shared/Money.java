package com.storefront.shared;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Currency;

/**
 * Money — immutable value object for monetary amounts.
 * ══════════════════════════════════════════════════════
 *
 * Wraps BigDecimal with a Currency to prevent accidental mixing
 * of amounts in different currencies, and centralises rounding rules.
 *
 * <pre>{@code
 * Money price    = Money.of("29.99", "USD");
 * Money tax      = price.multiply(new BigDecimal("0.08"));
 * Money subtotal = price.add(tax);
 * String display = price.toDisplayString();  // "$29.99"
 * }</pre>
 *
 * jOOQ mapping: NUMERIC(12,2) columns are mapped directly to BigDecimal
 * by jOOQ. Convert to/from Money at the service layer, not in repositories.
 */
public record Money(BigDecimal amount, Currency currency) {

    public static final Currency USD = Currency.getInstance("USD");

    public Money {
        if (amount == null)   throw new IllegalArgumentException("amount must not be null");
        if (currency == null) throw new IllegalArgumentException("currency must not be null");
        amount = amount.setScale(currency.getDefaultFractionDigits(), RoundingMode.HALF_UP);
    }

    // ─── Factory methods ───────────────────────────────────────────────────────

    public static Money of(BigDecimal amount, Currency currency) {
        return new Money(amount, currency);
    }

    public static Money of(String amount, String currencyCode) {
        return new Money(new BigDecimal(amount), Currency.getInstance(currencyCode));
    }

    public static Money ofUsd(BigDecimal amount) {
        return new Money(amount, USD);
    }

    public static Money ofUsd(String amount) {
        return ofUsd(new BigDecimal(amount));
    }

    public static Money zero(Currency currency) {
        return new Money(BigDecimal.ZERO, currency);
    }

    // ─── Arithmetic ───────────────────────────────────────────────────────────

    public Money add(Money other) {
        assertSameCurrency(other);
        return new Money(amount.add(other.amount), currency);
    }

    public Money subtract(Money other) {
        assertSameCurrency(other);
        return new Money(amount.subtract(other.amount), currency);
    }

    public Money multiply(BigDecimal factor) {
        return new Money(amount.multiply(factor), currency);
    }

    public Money multiply(int factor) {
        return multiply(BigDecimal.valueOf(factor));
    }

    // ─── Comparison helpers ───────────────────────────────────────────────────

    public boolean isZero()     { return amount.compareTo(BigDecimal.ZERO) == 0; }
    public boolean isPositive() { return amount.compareTo(BigDecimal.ZERO) > 0;  }
    public boolean isNegative() { return amount.compareTo(BigDecimal.ZERO) < 0;  }

    public boolean isGreaterThan(Money other) {
        assertSameCurrency(other);
        return amount.compareTo(other.amount) > 0;
    }

    public boolean isLessThan(Money other) {
        assertSameCurrency(other);
        return amount.compareTo(other.amount) < 0;
    }

    // ─── Display ──────────────────────────────────────────────────────────────

    /** Returns the raw BigDecimal for persistence (jOOQ / DB writes). */
    public BigDecimal toBigDecimal() { return amount; }

    @Override
    public String toString() {
        return amount.toPlainString() + " " + currency.getCurrencyCode();
    }

    // ─── Internal ─────────────────────────────────────────────────────────────

    private void assertSameCurrency(Money other) {
        if (!currency.equals(other.currency)) {
            throw new IllegalArgumentException(
                "Cannot operate on different currencies: %s vs %s"
                    .formatted(currency, other.currency));
        }
    }
}
