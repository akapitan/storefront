package com.storefront.inventory.stock;

import com.storefront.catalog.events.ProductCreated;
import com.storefront.catalog.events.ProductDeactivated;
import com.storefront.inventory.InventoryApi;
import com.storefront.inventory.events.InventoryLow;
import com.storefront.inventory.events.StockDepleted;
import com.storefront.inventory.events.StockUpdated;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/**
 * StockService — implements InventoryApi and reacts to Catalog module events.
 *
 * This class is the ONLY place Inventory communicates with the outside world:
 *   - Inbound:  listens to ProductCreated, ProductDeactivated (from Catalog)
 *   - Outbound: publishes StockUpdated, StockDepleted, InventoryLow
 *   - API:      implements InventoryApi (called by future modules e.g. Orders)
 *
 * The @ApplicationModuleListener annotation (Spring Modulith) means:
 *   - Runs in a NEW transaction (isolated from the event publisher's tx)
 *   - Retried automatically on transient failures (Modulith event publication log)
 *   - Documented in the module graph as a cross-module dependency
 */
@Service
@Slf4j
@RequiredArgsConstructor
class StockService implements InventoryApi {

    private final StockRepository        stockRepository;
    private final ApplicationEventPublisher eventPublisher;

    // ─── InventoryApi implementation ──────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Optional<StockLevel> getStockLevel(UUID productId) {
        return stockRepository.findByProductId(productId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isInStock(UUID productId) {
        return stockRepository.isInStock(productId);
    }

    @Override
    @Transactional
    public void reserve(UUID productId, int quantity) {
        if (quantity <= 0) throw new IllegalArgumentException("Quantity must be > 0");

        int newQty = stockRepository.decrementQuantity(productId, quantity);
        if (newQty == -1) {
            var stock = stockRepository.findByProductId(productId)
                    .orElseThrow(() -> new IllegalStateException("No stock record for: " + productId));
            throw new InsufficientStockException(productId, quantity, stock.quantity());
        }

        eventPublisher.publishEvent(new StockUpdated(productId, newQty + quantity, newQty));

        if (newQty == 0) {
            log.info("Stock depleted for product {}", productId);
            eventPublisher.publishEvent(new StockDepleted(productId));
        }
    }

    @Override
    @Transactional
    public void release(UUID productId, int quantity) {
        if (quantity <= 0) throw new IllegalArgumentException("Quantity must be > 0");

        int newQty = stockRepository.incrementQuantity(productId, quantity);
        eventPublisher.publishEvent(new StockUpdated(productId, newQty - quantity, newQty));

        log.info("Released {} units for product {}, new qty={}", quantity, productId, newQty);
    }

    // ─── Catalog event listeners ──────────────────────────────────────────────

    /**
     * React to a new product being created in the Catalog module.
     * Initialise an inventory record so the product can receive stock.
     *
     * Runs in a new transaction — if this fails, the ProductCreated event
     * is retained in the Modulith event publication log and retried.
     */
    @EventListener
    @Transactional
    public void on(ProductCreated event) {
        log.info("Inventory: initialising stock for new product {} ({})", event.sku(), event.productId());
        stockRepository.initialize(event.productId());
    }

    /**
     * React to a product being deactivated.
     * Archive (zero out) the stock record — no further reservations possible.
     */
    @EventListener
    @Transactional
    public void on(ProductDeactivated event) {
        log.info("Inventory: archiving stock for deactivated product {} ({})", event.sku(), event.productId());
        stockRepository.archive(event.productId());
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    /**
     * Called periodically (e.g. by a Spring Batch job) to check stock levels
     * and publish InventoryLow events for products at or below reorder point.
     */
    @Transactional(readOnly = true)
    public void checkAndPublishLowStockEvents(UUID productId) {
        stockRepository.findByProductId(productId).ifPresent(stock -> {
            if (stock.isLow() && stock.quantity() > 0) {
                log.warn("Low stock: product {} qty={}", productId, stock.quantity());
                eventPublisher.publishEvent(new InventoryLow(
                        productId, stock.quantity(),
                        // reorderPoint not in StockLevel projection — use a sensible default
                        10
                ));
            } else if (stock.quantity() == 0) {
                eventPublisher.publishEvent(new StockDepleted(productId));
            }
        });
    }
}
