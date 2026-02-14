@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List
@import java.util.UUID

@param UUID categoryId
@param List<ProductSummary> products
@param boolean hasMore
@param int nextPage
@param String sort

@template.layouts.main(
    title = "Products",
    content = @`
        @template.catalog.product-grid-content(
            categoryId = categoryId,
            products = products,
            hasMore = hasMore,
            nextPage = nextPage,
            sort = sort
        )
    `
)

