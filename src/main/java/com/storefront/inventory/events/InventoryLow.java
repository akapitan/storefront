package com.storefront.inventory.events;

import com.storefront.shared.DomainEvent;
import java.util.UUID;

/**
 * Published when stock drops at or below the reorder point.
 * Catalog reacts to show a "Low stock" badge on the product listing.
 */
public record InventoryLow(
        UUID productId,
        int  currentQuantity,
        int  reorderPoint
) implements DomainEvent {}
