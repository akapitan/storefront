package com.storefront.shared;


/**
 * DomainEvent — base record for all Spring ApplicationEvents in this modulith.
 * ══════════════════════════════════════════════════════════════════════════════
 *
 * Every cross-module event extends this record. The eventId and occurredOn
 * fields are set automatically — subclasses only carry business payload.
 *
 * Publishing (inside any module's service):
 * <pre>{@code
 * public record ProductCreated(
 *         UUID productId,
 *         String sku,
 *         String name
 * ) implements DomainEvent {}
 *
 * // In ProductService:
 * eventPublisher.publishEvent(new ProductCreated(product.getId(), product.getSku(), product.getName()));
 * }</pre>
 *
 * Listening (in a different module — never the publishing module):
 * <pre>{@code
 * @ApplicationModuleListener          // Spring Modulith annotation
 * public void on(ProductCreated event) {
 *     stockService.initializeStock(event.productId());
 * }
 * }</pre>
 *
 * @ApplicationModuleListener is preferred over @EventListener because it:
 *   - Documents that the listener belongs to a different module
 *   - Runs in a new transaction by default (isolated from publisher's transaction)
 *   - Is async by default in Spring Modulith 1.1+
 */
public interface DomainEvent {
}
