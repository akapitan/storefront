package com.storefront.inventory.domain.model;

import com.storefront.inventory.InventoryApi.StockLevel;

import java.util.Optional;
import java.util.UUID;

public interface StockRepository {

    Optional<StockLevel> findBySkuId(UUID skuId);

    boolean isInStock(UUID skuId);

    void initialize(UUID skuId);

    int decrementQuantity(UUID skuId, int amount);

    int incrementQuantity(UUID skuId, int amount);

    void archive(UUID skuId);
}
