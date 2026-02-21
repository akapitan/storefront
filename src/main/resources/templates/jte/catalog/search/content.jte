@import com.storefront.catalog.ProductApi.ProductGroupSummary
@import java.util.List

@param List<ProductGroupSummary> results
@param int totalItems
@param int totalPages
@param int currentPage
@param boolean hasNext
@param boolean hasPrev
@param String query

<div class="search-results">
    <h2>Search Results for "${query}"</h2>
    <p>${totalItems} results found</p>

    @if(!results.isEmpty())
        <div class="product-group-grid">
            @for(var group : results)
                <a href="/catalog/product/${group.slug()}"
                   class="product-group-card"
                   hx-get="/catalog/product/${group.slug()}"
                   hx-target="#main-content"
                   hx-push-url="true">
                    @if(group.overviewImageUrl() != null)
                        <img src="${group.overviewImageUrl()}"
                             alt="${group.name()}"
                             loading="lazy"/>
                    @else
                        <div class="no-image">No image</div>
                    @endif

                    <div class="product-group-card-info">
                        <div class="product-group-card-name">${group.name()}</div>
                        @if(group.subtitle() != null)
                            <div class="product-group-card-subtitle">${group.subtitle()}</div>
                        @endif
                        <div class="product-group-card-meta">
                            <span class="product-group-card-count">${group.skuCount()} products</span>
                            @if(group.minPriceUsd() != null)
                                <span class="product-group-card-price">from ${com.storefront.shared.web.TemplateHelpers.formatCurrency(group.minPriceUsd())}</span>
                            @endif
                        </div>
                        @if(group.anyInStock())
                            <span class="stock-badge stock-in">In Stock</span>
                        @else
                            <span class="stock-badge stock-out">Out of Stock</span>
                        @endif
                    </div>
                </a>
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
