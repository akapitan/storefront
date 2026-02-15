package com.storefront.inventory.events;

import com.storefront.shared.DomainEvent;
import java.util.UUID;

/** Published when stock drops at or below the reorder point. */
public record InventoryLow(
        UUID skuId,
        int  currentQuantity,
        int  reorderPoint
) implements DomainEvent {}
