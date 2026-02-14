package com.storefront.inventory.events;

import com.storefront.shared.DomainEvent;
import java.util.UUID;

/** Published when stock quantity reaches zero. Catalog reacts to mark product out-of-stock. */
public record StockDepleted(UUID productId) implements DomainEvent {}
