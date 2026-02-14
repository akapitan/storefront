@import com.storefront.catalog.CatalogApi.ProductDetail
@import com.fasterxml.jackson.databind.JsonNode

@param ProductDetail product

<article class="product-detail-page">
    <nav class="breadcrumb">
        <a href="/"
           hx-get="/"
           hx-target="#main-content"
           hx-push-url="true">Home</a> /
        <a href="/catalog">Catalog</a> /
        <span>${product.categoryName()}</span> /
        <span>${product.name()}</span>
    </nav>

    <section class="product-main">
        <!-- Image gallery -->
        <div class="product-images">
            @if(product.imageKeys() != null && !product.imageKeys().isEmpty())
                @for(var key : product.imageKeys())
                    <div class="image-slot">
                        <img src="/assets/images/${key}"
                             alt="${product.name()}"
                             loading="lazy"/>
                    </div>
                @endfor
            @else
                <div class="image-slot">
                    <div class="no-image">No Image Available</div>
                </div>
            @endif
        </div>

        <!-- Product details -->
        <div class="product-details">
            <h1>${product.name()}</h1>
            <p class="sku">SKU: ${product.sku()}</p>
            <p class="price">${com.storefront.shared.web.TemplateHelpers.formatCurrency(product.price())}</p>

            <div class="description">${product.description()}</div>

            @* Specifications from JSONB attributes *@
            @if(product.attributes() != null)
                <table class="specs-table">
                    <caption>Specifications</caption>
                    <tbody>
                        @* Note: This requires a Spring bean to render JsonNode as rows *@
                        @* For now, this will be handled by a custom method or in controller *@
                    </tbody>
                </table>
            @endif

            <!-- Add to cart form -->
            <form hx-post="/cart/add"
                  hx-target="#cart-badge"
                  hx-swap="outerHTML">
                <input type="hidden" name="sku" value="${product.sku()}"/>
                <input type="number" name="qty" value="1" min="1" max="999"/>
                <button type="submit" class="btn-add-to-cart">Add to Cart</button>
            </form>
        </div>
    </section>
</article>

