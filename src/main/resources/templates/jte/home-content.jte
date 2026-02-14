@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List

@param List<ProductSummary> featuredProducts = null

<!-- Welcome Section -->
<section class="hero">
    <h1 class="page-title">Welcome to Our Industrial Supply Catalog</h1>
    <p class="page-subtitle">
        Find the parts you need from our extensive inventory of industrial components,
        hardware, tools, and supplies. Browse by category or use our powerful search.
    </p>
</section>

<!-- Featured Categories Grid -->
<section class="categories">
    <h2 class="mb-3">Featured Categories</h2>
    <div class="category-grid">
        <a class="category-card"
           hx-get="/catalog/category/696bc45d-e641-4dd0-b51a-2f019750ee6a"
           hx-target="#main-content"
           hx-push-url="true">
            <div class="category-card-title">Fasteners</div>
            <div class="category-card-description">
                Screws, bolts, nuts, washers, and threaded fasteners in various materials and finishes
            </div>
            <div class="category-card-count">1,234 products</div>
        </a>

        <a href="/catalog/category/hardware"
           class="category-card"
           hx-get="/catalog/category/hardware"
           hx-target="#main-content"
           hx-push-url="true">
            <div class="category-card-title">Hardware</div>
            <div class="category-card-description">
                Hinges, brackets, handles, and mounting hardware for industrial applications
            </div>
            <div class="category-card-count">892 products</div>
        </a>

        <a href="/catalog/category/tools"
           class="category-card"
           hx-get="/catalog/category/tools"
           hx-target="#main-content"
           hx-push-url="true">
            <div class="category-card-title">Tools</div>
            <div class="category-card-description">
                Hand tools, power tools, measuring instruments, and accessories
            </div>
            <div class="category-card-count">2,456 products</div>
        </a>

        <a class="category-card"
           hx-get="/catalog/category/electrical"
           hx-target="#main-content"
           hx-push-url="true">
            <div class="category-card-title">Electrical</div>
            <div class="category-card-description">
                Wiring, connectors, switches, and electrical components for all applications
            </div>
            <div class="category-card-count">1,567 products</div>
        </a>

        <a href="/catalog/category/plumbing"
           class="category-card"
           hx-get="/catalog/category/plumbing"
           hx-target="#main-content"
           hx-push-url="true">
            <div class="category-card-title">Plumbing</div>
            <div class="category-card-description">
                Pipes, fittings, valves, and plumbing supplies in multiple materials
            </div>
            <div class="category-card-count">987 products</div>
        </a>

        <a href="/catalog/category/safety"
           class="category-card"
           hx-get="/catalog/category/safety"
           hx-target="#main-content"
           hx-push-url="true">
            <div class="category-card-title">Safety Equipment</div>
            <div class="category-card-description">
                Personal protective equipment, safety gear, and protective equipment
            </div>
            <div class="category-card-count">654 products</div>
        </a>
    </div>
</section>

<!-- Featured Products Section -->
@if(featuredProducts != null && !featuredProducts.isEmpty())
    <section class="featured-products mt-4">
        <h2 class="mb-3">Featured Products</h2>
        <div class="product-grid">
            @for(var product : featuredProducts)
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
                            <div class="no-image">No Image Available</div>
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
    </section>
@endif

