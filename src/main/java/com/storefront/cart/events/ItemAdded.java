package com.storefront.cart.events;

import com.storefront.shared.DomainEvent;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * ItemAdded — published when a SKU is added to cart or quantity increased.
 */
public record ItemAdded(
        UUID       cartId,
        UUID       itemId,
        UUID       skuId,
        String     partNumber,
        int        quantity,
        BigDecimal unitPrice
) implements DomainEvent {}
