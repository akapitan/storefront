package com.storefront.catalog.events;

import com.storefront.shared.DomainEvent;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * ProductUpdated — published when a product's core fields change.
 * Listeners can use this to invalidate derived state (search index, caches).
 */
public record ProductUpdated(
        UUID   productId,
        String sku,
        String name,
        BigDecimal price
) implements DomainEvent {}
