@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.ProductApi.FacetGroup
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param List<FacetGroup> facets = java.util.List.of()
@param Map<Integer, List<Integer>> enumFilters = java.util.Map.of()
@param Map<Integer, ?> rangeFilters = java.util.Map.of()

<div class="filter-sidebar">
    <h3 class="filter-sidebar-title">Filter by</h3>

    @if(facets.isEmpty())
        <p class="filter-section-placeholder">No filters available.</p>
    @else
        <form id="category-filter-form">
            @for(var facet : facets)
                <div class="filter-section">
                    <div class="filter-section-header">
                        ${facet.label()}
                        @if(facet.unitLabel() != null)
                            <span class="filter-unit">(${facet.unitLabel()})</span>
                        @endif
                    </div>

                    @if(facet.filterWidget().equals("checkbox"))
                        @template.catalog.category.filter-widgets.checkbox(
                            category = category, facet = facet, enumFilters = enumFilters)
                    @elseif(facet.filterWidget().equals("dropdown"))
                        @template.catalog.category.filter-widgets.dropdown(
                            category = category, facet = facet, enumFilters = enumFilters)
                    @elseif(facet.filterWidget().equals("image_grid"))
                        @template.catalog.category.filter-widgets.image-grid(
                            category = category, facet = facet, enumFilters = enumFilters)
                    @elseif(facet.filterWidget().equals("image_list"))
                        @template.catalog.category.filter-widgets.image-list(
                            category = category, facet = facet, enumFilters = enumFilters)
                    @elseif(facet.filterWidget().equals("range"))
                        @template.catalog.category.filter-widgets.range(
                            category = category, facet = facet, rangeFilters = rangeFilters)
                    @elseif(facet.filterWidget().equals("toggle"))
                        @template.catalog.category.filter-widgets.toggle(
                            category = category, facet = facet, enumFilters = enumFilters)
                    @endif
                </div>
            @endfor

            <button type="button"
                    class="filter-clear-all"
                    hx-get="/catalog/category/${category.slug()}"
                    hx-target="#main-content"
                    hx-push-url="true">
                Clear All Filters
            </button>
        </form>
    @endif
</div>
