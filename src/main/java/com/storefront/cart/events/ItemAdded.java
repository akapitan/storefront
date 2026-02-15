package com.storefront.cart.events;

import com.storefront.shared.DomainEvent;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * ItemAdded — published when a product is added to cart or quantity increased.
 */
public record ItemAdded(
        UUID       cartId,
        UUID       itemId,
        UUID       productId,
        String     productSku,
        int        quantity,
        BigDecimal unitPrice
) implements DomainEvent {}

