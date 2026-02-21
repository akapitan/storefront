@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.ProductApi.FacetGroup
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param FacetGroup facet
@param Map<Integer, List<Integer>> enumFilters

@if(!facet.options().isEmpty())
    !{var option = facet.options().get(0);}
    !{var isActive = enumFilters.getOrDefault(facet.attributeId(), java.util.List.of())
            .contains(option.optionId());}
    <label class="facet-toggle">
        <input type="checkbox"
               name="enum_${facet.attributeId()}"
               value="${option.optionId()}"
               role="switch"
               checked="${isActive}"
               hx-get="/catalog/category/${category.slug()}"
               hx-target="#main-content"
               hx-include="#category-filter-form"
               hx-push-url="true"/>
        <span class="toggle-label">${facet.label()}</span>
        <span class="toggle-count">(${option.skuCount()})</span>
    </label>
@endif
