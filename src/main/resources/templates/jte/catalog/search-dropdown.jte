@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List

@param List<ProductSummary> results
@param int totalItems
@param String query

@if(!results.isEmpty())
    <div class="search-dropdown-results">
        <div class="search-dropdown-header">
            <span class="search-result-count">${results.size()} of ${totalItems} results</span>
        </div>

        <div class="search-dropdown-items">
            @for(var product : results)
                <a href="/catalog/product/${product.sku()}"
                   class="search-dropdown-item"
                   hx-get="/catalog/product/${product.sku()}"
                   hx-target="#main-content"
                   hx-push-url="true">
                    @if(product.thumbnailKey() != null)
                        <img src="/assets/images/${product.thumbnailKey()}"
                             alt="${product.name()}"
                             class="search-item-thumbnail"/>
                    @else
                        <div class="search-item-thumbnail-placeholder">
                            <span>No Image</span>
                        </div>
                    @endif

                    <div class="search-item-info">
                        <div class="search-item-name">${product.name()}</div>
                        <div class="search-item-sku">SKU: ${product.sku()}</div>
                        <div class="search-item-price">${com.storefront.shared.web.TemplateHelpers.formatCurrency(product.price())}</div>
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
                    View all ${totalItems} results →
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

