@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List
@import java.util.UUID

@param UUID categoryId
@param List<ProductSummary> products
@param boolean hasMore
@param int nextPage
@param String sort

<div id="grid-root">
    <!-- Sort controls -->
    <div class="sort-bar">
        <span>Sort by:</span>
        <a href="/catalog/category/${String.valueOf(categoryId)}?sort=default"
           class="${sort.equals("default") ? "active" : ""}"
           hx-get="/catalog/category/${String.valueOf(categoryId)}?sort=default"
           hx-target="#product-grid"
           hx-push-url="true">Featured</a>

        <a href="/catalog/category/${String.valueOf(categoryId)}?sort=price_asc"
           class="${sort.equals("price_asc") ? "active" : ""}"
           hx-get="/catalog/category/${String.valueOf(categoryId)}?sort=price_asc"
           hx-target="#product-grid"
           hx-push-url="true">Price ↑</a>

        <a href="/catalog/category/${String.valueOf(categoryId)}?sort=price_desc"
           class="${sort.equals("price_desc") ? "active" : ""}"
           hx-get="/catalog/category/${String.valueOf(categoryId)}?sort=price_desc"
           hx-target="#product-grid"
           hx-push-url="true">Price ↓</a>

        <a href="/catalog/category/${String.valueOf(categoryId)}?sort=name"
           class="${sort.equals("name") ? "active" : ""}"
           hx-get="/catalog/category/${String.valueOf(categoryId)}?sort=name"
           hx-target="#product-grid"
           hx-push-url="true">Name</a>
    </div>

    <!-- Product cards grid -->
    <div id="product-grid">
        @template.catalog.product-cards(
            categoryId = categoryId,
            products = products,
            hasMore = hasMore,
            nextPage = nextPage,
            sort = sort
        )
    </div>
</div>

