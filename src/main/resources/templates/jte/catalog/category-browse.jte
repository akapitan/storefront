@import com.storefront.catalog.CatalogApi.CategoryNode
@import com.storefront.catalog.CatalogApi.CategoryBreadcrumb
@import com.storefront.catalog.CatalogApi.ProductGroupSummary
@import java.util.List

@param CategoryNode category
@param List<ProductGroupSummary> groups
@param boolean hasMore
@param int nextPage
@param List<CategoryNode> children
@param List<CategoryBreadcrumb> breadcrumb

@template.layouts.main(
    title = category.name(),
    content = @`
        @template.catalog.category-browse-content(
            category = category,
            groups = groups,
            hasMore = hasMore,
            nextPage = nextPage,
            children = children,
            breadcrumb = breadcrumb
        )
    `
)
