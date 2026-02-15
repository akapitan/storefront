package com.storefront.inventory.events;

import com.storefront.shared.DomainEvent;

import java.util.UUID;

/** Published when stock quantity changes for any reason. */
public record StockUpdated(
        UUID skuId,
        int  previousQuantity,
        int  newQuantity
) implements DomainEvent {}
