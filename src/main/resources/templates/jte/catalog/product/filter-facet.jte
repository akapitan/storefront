@import com.storefront.catalog.ProductApi.ProductGroupDetail
@import com.storefront.catalog.ProductApi.FacetGroup

@param ProductGroupDetail group
@param FacetGroup facet

<div class="filter-facet">
    <h4 class="facet-label">
        ${facet.label()}
        @if(facet.unitLabel() != null)
            <span class="facet-unit">(${facet.unitLabel()})</span>
        @endif
    </h4>

    @if(facet.filterWidget().equals("checkbox"))
        <div class="facet-options">
            @for(var option : facet.options())
                <label class="facet-option">
                    <input type="checkbox"
                           name="enum_${facet.attributeId()}"
                           value="${option.optionId()}"
                           hx-get="/catalog/product/${group.slug()}/filter"
                           hx-target="#variant-table-container"
                           hx-include="#filter-form"
                           hx-swap="innerHTML"/>
                    <span class="facet-option-label">
                        ${option.displayValue() != null ? option.displayValue() : option.value()}
                    </span>
                    <span class="facet-option-count">(${option.skuCount()})</span>
                </label>
            @endfor
        </div>
    @elseif(facet.filterWidget().equals("range"))
        <div class="facet-range">
            <input type="number"
                   name="range_min_${facet.attributeId()}"
                   placeholder="Min"
                   step="any"
                   class="facet-range-input"
                   hx-get="/catalog/product/${group.slug()}/filter"
                   hx-target="#variant-table-container"
                   hx-include="#filter-form"
                   hx-trigger="input changed delay:500ms"
                   hx-swap="innerHTML"/>
            <span class="facet-range-sep">to</span>
            <input type="number"
                   name="range_max_${facet.attributeId()}"
                   placeholder="Max"
                   step="any"
                   class="facet-range-input"
                   hx-get="/catalog/product/${group.slug()}/filter"
                   hx-target="#variant-table-container"
                   hx-include="#filter-form"
                   hx-trigger="input changed delay:500ms"
                   hx-swap="innerHTML"/>
            @if(facet.unitLabel() != null)
                <span class="facet-range-unit">${facet.unitLabel()}</span>
            @endif
        </div>
    @endif
</div>
