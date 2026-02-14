@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List
@import java.util.UUID

@param UUID categoryId
@param List<ProductSummary> products
@param boolean hasMore
@param int nextPage
@param String sort

@if(!products.isEmpty())
    @for(int i = 0; i < products.size(); i++)
        !{var product = products.get(i);}
        !{var isLast = i == products.size() - 1;}
        <div class="product-card${isLast && hasMore ? " scroll-sentinel" : ""}">
            @* Infinite scroll trigger on last card *@
            @if(isLast && hasMore)
                <div hx-get="/catalog/category/${String.valueOf(categoryId)}/more?page=${nextPage}&sort=${sort}"
                     hx-trigger="revealed"
                     hx-target="#product-grid"
                     hx-swap="beforeend">
                </div>
            @endif

            @* Product thumbnail *@
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

            @* Product info *@
            <div class="product-info">
                <a href="/catalog/product/${product.sku()}"
                   class="product-name"
                   hx-get="/catalog/product/${product.sku()}"
                   hx-target="#main-content"
                   hx-push-url="true">${product.name()}</a>

                <span class="product-sku">${product.sku()}</span>

                <span class="product-price">${com.storefront.shared.web.TemplateHelpers.formatCurrency(product.price())}</span>

                @* Quick view button *@
                <button hx-get="/catalog/product/${product.sku()}/quick-view"
                        hx-target="#modal-container"
                        hx-swap="innerHTML"
                        class="btn-quick-view">Quick view</button>
            </div>
        </div>
    @endfor
@else
    <!-- Empty state -->
    <div class="empty-state">
        No products found in this category.
    </div>
@endif

<!-- Modal container -->
<div id="modal-container"></div>



