@import com.storefront.catalog.CatalogApi.CategoryNode
@import java.util.List

<aside class="sidebar" id="sidebar">
    <nav class="category-nav">
        <h2 class="category-nav-title">Product Categories</h2>
        <ul class="category-tree" id="category-tree"
            hx-get="/catalog/categories/top-level"
            hx-trigger="load"
            hx-swap="innerHTML">
            <%-- Categories loaded via HTMX on page load --%>
            <li class="text-muted">Loading categories...</li>
        </ul>
    </nav>
</aside>
