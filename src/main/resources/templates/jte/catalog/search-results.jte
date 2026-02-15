@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List

@param List<ProductSummary> results
@param int totalItems
@param int totalPages
@param int currentPage
@param boolean hasNext
@param boolean hasPrev
@param String query

@template.layouts.main(
    title = "Search Results",
    content = @`
        @template.catalog.search-results-content(
            results = results,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage,
            hasNext = hasNext,
            hasPrev = hasPrev,
            query = query
        )
    `
)


