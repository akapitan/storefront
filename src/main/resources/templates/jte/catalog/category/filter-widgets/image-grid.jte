@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.ProductApi.FacetGroup
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param FacetGroup facet
@param Map<Integer, List<Integer>> enumFilters

<div class="facet-image-grid">
    @for(var option : facet.options())
        !{var isActive = enumFilters.getOrDefault(facet.attributeId(), java.util.List.of())
                .contains(option.optionId());}
        <label class="image-grid-tile ${isActive ? "active" : ""}">
            <input type="checkbox"
                   name="enum_${facet.attributeId()}"
                   value="${option.optionId()}"
                   checked="${isActive}"
                   hx-get="/catalog/category/${category.slug()}"
                   hx-target="#main-content"
                   hx-include="#category-filter-form"
                   hx-push-url="true"/>
            @if(option.imageUrl() != null)
                <img src="${option.imageUrl()}" alt="${option.displayValue() != null ? option.displayValue() : option.value()}" class="tile-icon"/>
            @endif
            <span class="tile-label">${option.displayValue() != null ? option.displayValue() : option.value()}</span>
            <span class="tile-count">(${option.skuCount()})</span>
        </label>
    @endfor
</div>
