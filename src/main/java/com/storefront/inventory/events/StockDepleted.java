package com.storefront.inventory.events;

import com.storefront.shared.DomainEvent;
import java.util.UUID;

/** Published when stock quantity reaches zero. */
public record StockDepleted(UUID skuId) implements DomainEvent {}
