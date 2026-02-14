@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List

@param List<ProductSummary> results
@param long totalItems
@param int totalPages
@param int currentPage
@param boolean hasNext
@param boolean hasPrev
@param String query

<div class="search-results">
    <h2>Search Results for "${query}"</h2>
    <p>${totalItems} results found</p>

    @if(!results.isEmpty())
        <div class="product-grid">
            @for(var product : results)
                <div class="product-card">
                    <a href="/catalog/product/${product.sku()}"
                       hx-get="/catalog/product/${product.sku()}"
                       hx-target="#main-content"
                       hx-push-url="true">
                        @if(product.thumbnailKey() != null)
                            <img src="/assets/images/${product.thumbnailKey()}"
                                 alt="${product.name()}"
                                 loading="lazy"/>
                        @else
                            <div class="no-image">No image</div>
                        @endif
                    </a>

                    <div class="product-info">
                        <a href="/catalog/product/${product.sku()}"
                           class="product-name"
                           hx-get="/catalog/product/${product.sku()}"
                           hx-target="#main-content"
                           hx-push-url="true">${product.name()}</a>

                        <span class="product-sku">${product.sku()}</span>

                        <span class="product-price">${com.storefront.shared.web.TemplateHelpers.formatCurrency(product.price())}</span>
                    </div>
                </div>
            @endfor
        </div>

        <!-- Pagination -->
        @if(totalPages > 1)
            <div class="pagination">
                @if(hasPrev)
                    <a href="/catalog/search?q=${query}&page=${currentPage - 1}"
                       hx-get="/catalog/search?q=${query}&page=${currentPage - 1}"
                       hx-target="#main-content"
                       hx-push-url="true">&larr; Previous</a>
                @endif

                <span>Page ${currentPage + 1} of ${totalPages}</span>

                @if(hasNext)
                    <a href="/catalog/search?q=${query}&page=${currentPage + 1}"
                       hx-get="/catalog/search?q=${query}&page=${currentPage + 1}"
                       hx-target="#main-content"
                       hx-push-url="true">Next &rarr;</a>
                @endif
            </div>
        @endif
    @else
        <div class="empty-state">
            No products found matching "${query}".
        </div>
    @endif
</div>

