@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.ProductApi.ProductGroupSummary
@import com.storefront.catalog.ProductApi.AttributeSummary
@import java.util.List

@param CategoryNode category
@param List<ProductGroupSummary> groups
@param boolean hasMore
@param int nextPage
@param List<CategoryNode> children
@param List<CategoryBreadcrumb> breadcrumb
@param List<AttributeSummary> attributes = java.util.List.of()

@template.layouts.main(
    title = category.name(),
    content = @`
        @template.catalog.category.content(
            category = category,
            groups = groups,
            hasMore = hasMore,
            nextPage = nextPage,
            children = children,
            breadcrumb = breadcrumb
        )
    `,
    sidebarContent = @`
        @template.catalog.category.filter-sidebar(
            category = category,
            attributes = attributes
        )
    `
)
