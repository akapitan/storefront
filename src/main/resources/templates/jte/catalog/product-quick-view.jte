@import com.storefront.catalog.CatalogApi.ProductDetail

@param ProductDetail product

<div class="product-quick-view">
    <button class="modal-close"
            onclick="document.getElementById('modal-container').innerHTML = ''">✕</button>

    <div class="quick-view-inner">
        <!-- Image -->
        <div class="quick-view-image">
            @if(product.imageKeys() != null && !product.imageKeys().isEmpty())
                <img src="/assets/images/${product.imageKeys().get(0)}"
                     alt="${product.name()}" />
            @else
                <div class="no-image">No Image Available</div>
            @endif
        </div>

        <!-- Info -->
        <div class="quick-view-info">
            <h2>${product.name()}</h2>
            <p class="sku">SKU: ${product.sku()}</p>
            <p class="category">${product.categoryName()}</p>
            <p class="price">${com.storefront.shared.web.TemplateHelpers.formatCurrency(product.price())}</p>
            <p class="description">${product.description()}</p>

            <a href="/catalog/product/${product.sku()}"
               hx-get="/catalog/product/${product.sku()}"
               hx-target="#main-content"
               hx-push-url="true"
               class="btn-view-full">View full details →</a>
        </div>
    </div>
</div>

