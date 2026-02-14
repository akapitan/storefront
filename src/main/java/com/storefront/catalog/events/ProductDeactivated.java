package com.storefront.catalog.events;

import com.storefront.shared.DomainEvent;

import java.util.UUID;

/**
 * ProductDeactivated — published when a product is soft-deleted / deactivated.
 * Inventory reacts by archiving the stock record for this product.
 */
public record ProductDeactivated(
        UUID   productId,
        String sku
) implements DomainEvent {}
