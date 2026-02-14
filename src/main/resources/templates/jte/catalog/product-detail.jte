@import com.storefront.catalog.CatalogApi.ProductDetail

@param ProductDetail product

@template.layouts.main(
    title = product.name(),
    content = @`
        @template.catalog.product-detail-content(product = product)
    `
)

