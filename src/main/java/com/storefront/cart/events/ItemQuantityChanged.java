package com.storefront.cart.events;

import com.storefront.shared.DomainEvent;

import java.util.UUID;

/**
 * ItemQuantityChanged — published when item quantity is updated.
 */
public record ItemQuantityChanged(
        UUID cartId,
        UUID itemId,
        UUID skuId,
        int  previousQuantity,
        int  newQuantity
) implements DomainEvent {}
