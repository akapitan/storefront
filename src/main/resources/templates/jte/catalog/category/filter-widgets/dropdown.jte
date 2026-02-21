@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.ProductApi.FacetGroup
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param FacetGroup facet
@param Map<Integer, List<Integer>> enumFilters

<details class="facet-dropdown">
    <summary class="facet-dropdown-trigger">
        Select ${facet.label()}
        !{var activeCount = enumFilters.getOrDefault(facet.attributeId(), java.util.List.of()).size();}
        @if(activeCount > 0)
            <span class="active-count">${activeCount} selected</span>
        @endif
    </summary>
    <div class="facet-dropdown-body">
        <input type="text"
               class="facet-search-input"
               placeholder="Search ${facet.label()}..."
               oninput="this.closest('.facet-dropdown-body').querySelectorAll('.facet-option').forEach(el => {
                   el.style.display = el.querySelector('.facet-option-label').textContent.toLowerCase().includes(this.value.toLowerCase()) ? '' : 'none';
               })"/>
        <div class="facet-options">
            @for(var option : facet.options())
                !{var isActive = enumFilters.getOrDefault(facet.attributeId(), java.util.List.of())
                        .contains(option.optionId());}
                <label class="facet-option ${isActive ? "active" : ""}">
                    <input type="checkbox"
                           name="enum_${facet.attributeId()}"
                           value="${option.optionId()}"
                           checked="${isActive}"
                           hx-get="/catalog/category/${category.slug()}"
                           hx-target="#main-content"
                           hx-include="#category-filter-form"
                           hx-push-url="true"/>
                    <span class="facet-option-label">
                        ${option.displayValue() != null ? option.displayValue() : option.value()}
                    </span>
                    <span class="facet-option-count">(${option.skuCount()})</span>
                </label>
            @endfor
        </div>
    </div>
</details>
