package com.storefront.catalog.product;

import com.storefront.catalog.CatalogApi;
import com.storefront.catalog.events.ProductCreated;
import com.storefront.catalog.events.ProductDeactivated;
import com.storefront.catalog.events.ProductUpdated;
import com.storefront.shared.Pagination;
import com.storefront.shared.PageRequest;
import com.storefront.shared.Slice;
import com.storefront.shared.SliceRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/**
 * ProductService — implements CatalogApi and orchestrates Catalog use cases.
 *
 * This is the implementation behind the public CatalogApi interface.
 * It is package-private: only Spring wires it via the CatalogApi interface.
 * Other modules never import this class directly.
 *
 * Event publishing happens here — after the DB write succeeds, within the
 * same transaction. If the transaction rolls back, the event is not fired.
 */
@Service
@Slf4j
@RequiredArgsConstructor
class ProductService implements CatalogApi {

    private final ProductRepository       productRepository;
    private final ApplicationEventPublisher eventPublisher;

    // ─── CatalogApi implementation ────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Optional<ProductDetail> findBySku(String sku) {
        return productRepository.findBySku(sku);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<ProductDetail> findById(UUID productId) {
        return productRepository.findById(productId);
    }

    @Override
    @Transactional(readOnly = true)
    public Slice<ProductSummary> browseByCategory(UUID categoryId, SliceRequest request) {
        return productRepository.browseByCategory(categoryId, request);
    }

    @Override
    @Transactional(readOnly = true)
    public Pagination<ProductSummary> search(String query, PageRequest request) {
        return productRepository.search(query, request);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsAndActive(UUID productId) {
        return productRepository.existsAndActive(productId);
    }

    // ─── Write use cases ──────────────────────────────────────────────────────

    /**
     * Create a new product and publish ProductCreated.
     * Inventory will react by initialising a stock record.
     */
    @Transactional
    public UUID createProduct(CreateProductCommand cmd) {
        log.info("Creating product SKU={}", cmd.sku());

        var record = new com.storefront.jooq.tables.records.ProductRecord();
//                .setSku(cmd.sku())
//                .name(cmd.name())
//                .setDescription(cmd.description())
//                .setCategoryId(cmd.categoryId())
//                .setPrice(cmd.price())
//                .setUnitOfMeasure(cmd.unitOfMeasure())
//                .setActive(true);

        UUID productId = productRepository.save(record);

        // Publish after DB write — still inside same transaction.
        // If transaction rolls back, Spring Modulith will NOT deliver the event.
        eventPublisher.publishEvent(new ProductCreated(
                productId, cmd.sku(), cmd.name(), cmd.categoryId(), cmd.price()));

        log.info("Product created id={} SKU={}", productId, cmd.sku());
        return productId;
    }

    /**
     * Update an existing product and publish ProductUpdated.
     */
    @Transactional
    public void updateProduct(UpdateProductCommand cmd) {
        log.info("Updating product id={}", cmd.productId());

        var record = new com.storefront.jooq.tables.records.ProductRecord()
//                .setId(cmd.productId())
//                .setName(cmd.name())
//                .setDescription(cmd.description())
//                .setPrice(cmd.price())
                ;

        productRepository.save(record);

        eventPublisher.publishEvent(new ProductUpdated(
                cmd.productId(), null, cmd.name(), cmd.price()));
    }

    /**
     * Soft-delete a product and publish ProductDeactivated.
     * Inventory reacts by archiving the stock record.
     */
    @Transactional
    public void deactivateProduct(UUID productId) {
        var product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found: " + productId));

        log.info("Deactivating product id={} SKU={}", productId, product.sku());
        productRepository.deactivate(productId);

        eventPublisher.publishEvent(new ProductDeactivated(productId, product.sku()));
    }
}
