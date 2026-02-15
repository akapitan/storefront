package com.storefront.inventory.stock;

import com.storefront.inventory.InventoryApi;
import com.storefront.inventory.domain.model.StockRepository;
import com.storefront.inventory.events.InventoryLow;
import com.storefront.inventory.events.StockDepleted;
import com.storefront.inventory.events.StockUpdated;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
@Slf4j
@RequiredArgsConstructor
class StockService implements InventoryApi {

    private final StockRepository        stockRepository;
    private final ApplicationEventPublisher eventPublisher;

    // ─── InventoryApi implementation ──────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Optional<StockLevel> getStockLevel(UUID skuId) {
        return stockRepository.findBySkuId(skuId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isInStock(UUID skuId) {
        return stockRepository.isInStock(skuId);
    }

    @Override
    @Transactional
    public void reserve(UUID skuId, int quantity) {
        if (quantity <= 0) throw new IllegalArgumentException("Quantity must be > 0");

        int newQty = stockRepository.decrementQuantity(skuId, quantity);
        if (newQty == -1) {
            var stock = stockRepository.findBySkuId(skuId)
                    .orElseThrow(() -> new IllegalStateException("No stock record for: " + skuId));
            throw new InsufficientStockException(skuId, quantity, stock.quantity());
        }

        eventPublisher.publishEvent(new StockUpdated(skuId, newQty + quantity, newQty));

        if (newQty == 0) {
            log.info("Stock depleted for SKU {}", skuId);
            eventPublisher.publishEvent(new StockDepleted(skuId));
        }
    }

    @Override
    @Transactional
    public void release(UUID skuId, int quantity) {
        if (quantity <= 0) throw new IllegalArgumentException("Quantity must be > 0");

        int newQty = stockRepository.incrementQuantity(skuId, quantity);
        eventPublisher.publishEvent(new StockUpdated(skuId, newQty - quantity, newQty));

        log.info("Released {} units for SKU {}, new qty={}", quantity, skuId, newQty);
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public void checkAndPublishLowStockEvents(UUID skuId) {
        stockRepository.findBySkuId(skuId).ifPresent(stock -> {
            if (stock.isLow() && stock.quantity() > 0) {
                log.warn("Low stock: SKU {} qty={}", skuId, stock.quantity());
                eventPublisher.publishEvent(new InventoryLow(skuId, stock.quantity(), 10));
            } else if (stock.quantity() == 0) {
                eventPublisher.publishEvent(new StockDepleted(skuId));
            }
        });
    }
}
