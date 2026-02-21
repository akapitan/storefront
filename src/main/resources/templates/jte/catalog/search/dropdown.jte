@import com.storefront.catalog.ProductApi.ProductGroupSummary
@import java.util.List

@param List<ProductGroupSummary> results
@param int totalItems
@param String query

@if(!results.isEmpty())
    <div class="search-dropdown-results">
        <div class="search-dropdown-header">
            <span class="search-result-count">${results.size()} of ${totalItems} results</span>
        </div>

        <div class="search-dropdown-items">
            @for(var group : results)
                <a href="/catalog/product/${group.slug()}"
                   class="search-dropdown-item"
                   hx-get="/catalog/product/${group.slug()}"
                   hx-target="#main-content"
                   hx-push-url="true">
                    @if(group.overviewImageUrl() != null)
                        <img src="${group.overviewImageUrl()}"
                             alt="${group.name()}"
                             class="search-item-thumbnail"/>
                    @else
                        <div class="search-item-thumbnail-placeholder">
                            <span>No Image</span>
                        </div>
                    @endif

                    <div class="search-item-info">
                        <div class="search-item-name">${group.name()}</div>
                        @if(group.subtitle() != null)
                            <div class="search-item-sku">${group.subtitle()}</div>
                        @endif
                        @if(group.minPriceUsd() != null)
                            <div class="search-item-price">from ${com.storefront.shared.web.TemplateHelpers.formatCurrency(group.minPriceUsd())}</div>
                        @endif
                    </div>
                </a>
            @endfor
        </div>

        @if(totalItems > results.size())
            <div class="search-dropdown-footer">
                <a href="/catalog/search?q=${query}"
                   class="search-view-all"
                   hx-get="/catalog/search?q=${query}"
                   hx-target="#main-content"
                   hx-push-url="true">
                    View all ${totalItems} results
                </a>
            </div>
        @endif
    </div>
@else
    <div class="search-dropdown-empty">
        <div class="search-no-results">
            <p>No products found for "${query}"</p>
            <p class="search-suggestion">Try searching with different keywords</p>
        </div>
    </div>
@endif
