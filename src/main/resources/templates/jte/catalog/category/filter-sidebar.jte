@import com.storefront.catalog.ProductApi.AttributeSummary
@import com.storefront.catalog.CategoryApi.CategoryNode
@import java.util.List

@param CategoryNode category
@param List<AttributeSummary> attributes = java.util.List.of()

<div class="filter-sidebar">
    <h3 class="filter-sidebar-title">Filter by</h3>

    @for(var attr : attributes)
        <div class="filter-section">
            <div class="filter-section-header">${attr.label()}</div>
            <div class="filter-section-placeholder">Coming soon</div>
        </div>
    @endfor

    @if(attributes.isEmpty())
        <p class="filter-section-placeholder">No filters available for this category.</p>
    @endif

    <button type="button" class="filter-clear-all" disabled>
        Clear All Filters
    </button>
</div>
