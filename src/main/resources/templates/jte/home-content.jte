@import com.storefront.catalog.CatalogApi.CategoryNode
@import java.util.List

@param List<CategoryNode> categories = java.util.List.of()

<div class="mcm-category-grid">
    @for(var category : categories)
        <a href="/category/${category.slug()}"
           class="mcm-category-tile"
           hx-get="/category/${category.slug()}"
           hx-target="#main-content"
           hx-push-url="true">
            ${category.name()}
        </a>
    @endfor
</div>
