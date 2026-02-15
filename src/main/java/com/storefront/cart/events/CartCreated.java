package com.storefront.cart.events;

import com.storefront.shared.DomainEvent;

import java.util.UUID;

/**
 * CartCreated — published when a new shopping cart is created.
 * Typically happens when a user adds their first item.
 */
public record CartCreated(
        UUID   cartId,
        String sessionId,
        UUID   customerId      // NULL for anonymous carts
) implements DomainEvent {}

