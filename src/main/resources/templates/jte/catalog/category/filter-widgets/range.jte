@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.ProductApi.FacetGroup
@import com.storefront.catalog.ProductApi.NumericRange
@import java.util.Map

@param CategoryNode category
@param FacetGroup facet
@param Map<Integer, ?> rangeFilters

!{var range = (NumericRange) rangeFilters.get(facet.attributeId());}
!{var minVal = range != null ? range.min().toPlainString() : "";}
!{var maxVal = range != null ? range.max().toPlainString() : "";}
<div class="facet-range">
    <input type="number"
           name="range_min_${facet.attributeId()}"
           placeholder="Min"
           step="any"
           value="${minVal}"
           class="facet-range-input"
           hx-get="/catalog/category/${category.slug()}"
           hx-target="#main-content"
           hx-include="#category-filter-form"
           hx-trigger="input changed delay:500ms"
           hx-push-url="true"/>
    <span class="facet-range-sep">&ndash;</span>
    <input type="number"
           name="range_max_${facet.attributeId()}"
           placeholder="Max"
           step="any"
           value="${maxVal}"
           class="facet-range-input"
           hx-get="/catalog/category/${category.slug()}"
           hx-target="#main-content"
           hx-include="#category-filter-form"
           hx-trigger="input changed delay:500ms"
           hx-push-url="true"/>
    @if(facet.unitLabel() != null)
        <span class="facet-range-unit">${facet.unitLabel()}</span>
    @endif
</div>
