@import com.storefront.catalog.CatalogApi.CategoryNode
@import com.storefront.catalog.CatalogApi.CategoryBreadcrumb
@import com.storefront.catalog.CatalogApi.ProductGroupSummary
@import com.storefront.catalog.CatalogApi.AttributeSummary
@import java.util.List

@param CategoryNode category
@param List<ProductGroupSummary> groups
@param boolean hasMore
@param int nextPage
@param List<CategoryNode> children
@param List<CategoryBreadcrumb> breadcrumb
@param List<AttributeSummary> attributes = java.util.List.of()

<%-- Main content (swaps into #main-content) --%>
@template.catalog.category-browse-content(
    category = category,
    groups = groups,
    hasMore = hasMore,
    nextPage = nextPage,
    children = children,
    breadcrumb = breadcrumb
)

<%-- OOB sidebar swap --%>
<div id="sidebar-content" hx-swap-oob="innerHTML:#sidebar-content">
    @template.catalog.category-filter-sidebar(
        category = category,
        attributes = attributes
    )
</div>
