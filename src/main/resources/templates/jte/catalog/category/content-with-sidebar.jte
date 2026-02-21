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

<%-- Main content (swaps into #main-content) --%>
@template.catalog.category.content(
    category = category,
    groups = groups,
    hasMore = hasMore,
    nextPage = nextPage,
    children = children,
    breadcrumb = breadcrumb
)

<%-- OOB sidebar swap --%>
<div id="sidebar-content" hx-swap-oob="innerHTML:#sidebar-content">
    @template.catalog.category.filter-sidebar(
        category = category,
        attributes = attributes
    )
</div>
