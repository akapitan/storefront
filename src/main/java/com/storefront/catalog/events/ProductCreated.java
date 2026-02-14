package com.storefront.catalog.events;

import com.storefront.shared.DomainEvent;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * ProductCreated — published when a new product is saved to the catalog.
 *
 * Listeners (in other modules) react to this to set up their own state.
 * Currently consumed by: Inventory (initialises a stock record).
 *
 * Carries only the data listeners need — not the full product graph.
 */
public record ProductCreated(
        UUID   productId,
        String sku,
        String name,
        UUID   categoryId,
        BigDecimal price
) implements DomainEvent {}
