@import com.storefront.catalog.CatalogApi.CategoryNode
@import java.util.List

@param List<CategoryNode> categories = java.util.List.of()

<!-- Welcome Section -->
<section class="hero">
    <h1 class="page-title">Welcome to Our Industrial Supply Catalog</h1>
    <p class="page-subtitle">
        Find the parts you need from our extensive inventory of industrial components,
        hardware, tools, and supplies. Browse by category or use our powerful search.
    </p>
</section>

<!-- Categories Grid -->
<section class="categories">
    <h2 class="mb-3">Browse Categories</h2>
    <div class="category-grid">
        @for(var category : categories)
            <a href="/catalog/category/${category.slug()}"
               class="category-card"
               hx-get="/catalog/category/${category.slug()}"
               hx-target="#main-content"
               hx-push-url="true">
                <div class="category-card-title">${category.name()}</div>
                <div class="category-card-count">${category.groupCount()} product groups</div>
            </a>
        @endfor
    </div>
</section>
