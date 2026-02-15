package com.storefront.cart.events;

import com.storefront.shared.DomainEvent;

import java.util.UUID;

/**
 * ItemRemoved — published when a SKU is removed from cart.
 */
public record ItemRemoved(
        UUID cartId,
        UUID itemId,
        UUID skuId
) implements DomainEvent {}
