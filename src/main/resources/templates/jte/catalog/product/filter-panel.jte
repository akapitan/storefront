@import com.storefront.catalog.ProductApi.ProductGroupDetail
@import com.storefront.catalog.ProductApi.FacetGroup
@import java.util.List

@param ProductGroupDetail group
@param List<FacetGroup> facets

<form id="filter-form">
    <h3 class="filter-title">Refine Results</h3>

    @for(var facet : facets)
        @template.catalog.product.filter-facet(
            group = group,
            facet = facet
        )
    @endfor

    <button type="button"
            class="filter-clear-btn"
            hx-get="/catalog/product/${group.slug()}/filter"
            hx-target="#variant-table-container"
            hx-include="none"
            hx-swap="innerHTML">
        Clear All Filters
    </button>
</form>
