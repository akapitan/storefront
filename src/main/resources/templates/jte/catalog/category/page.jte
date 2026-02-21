@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.CategoryApi.FilteredCategory
@import com.storefront.catalog.CategoryApi.LeafGroupTable
@import com.storefront.catalog.ProductApi.FacetGroup
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param String viewMode
@param List<CategoryBreadcrumb> breadcrumb
@param List<CategoryNode> children = java.util.List.of()
@param List<FilteredCategory> filteredChildren = java.util.List.of()
@param List<FacetGroup> facets = java.util.List.of()
@param List<LeafGroupTable> groupTables = java.util.List.of()
@param Map<Integer, List<Integer>> enumFilters = java.util.Map.of()
@param Map<Integer, ?> rangeFilters = java.util.Map.of()

@template.layouts.main(
    title = category.name(),
    content = @`
        @if(viewMode.equals("top-level"))
            @template.catalog.category.top-level-content(
                category = category, breadcrumb = breadcrumb, children = children)
        @elseif(viewMode.equals("mid-level"))
            @template.catalog.category.browse-content(
                category = category, breadcrumb = breadcrumb,
                children = filteredChildren, enumFilters = enumFilters, rangeFilters = rangeFilters)
        @else
            @template.catalog.category.leaf-content(
                category = category, breadcrumb = breadcrumb,
                groupTables = groupTables, enumFilters = enumFilters, rangeFilters = rangeFilters)
        @endif
    `,
    sidebarContent = @`
        @if(!viewMode.equals("top-level"))
            @template.catalog.category.filter-sidebar(
                category = category, facets = facets,
                enumFilters = enumFilters, rangeFilters = rangeFilters)
        @endif
    `
)
