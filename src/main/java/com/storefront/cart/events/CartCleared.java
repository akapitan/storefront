package com.storefront.cart.events;

import com.storefront.shared.DomainEvent;

import java.util.UUID;

/**
 * CartCleared — published when all items are removed from cart.
 * Typically happens after order placement or manual clear.
 */
public record CartCleared(
        UUID cartId,
        int  itemsCleared
) implements DomainEvent {}

