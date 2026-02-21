@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.CategoryApi.CategoryNode
@import java.util.List

@param CategoryNode category
@param List<CategoryBreadcrumb> breadcrumb
@param List<CategoryNode> children

<div class="category-browse">
    <nav class="breadcrumb">
        <a href="/" hx-get="/" hx-target="#main-content" hx-push-url="true">Home</a>
        / <span>${category.name()}</span>
    </nav>

    <h1 class="page-title">${category.name()}</h1>

    <div class="subcategory-tile-grid">
        @for(var child : children)
            <a href="/catalog/category/${child.slug()}"
               class="subcategory-tile"
               hx-get="/catalog/category/${child.slug()}"
               hx-target="#main-content"
               hx-push-url="true">
                <div class="tile-name">${child.name()}</div>
                <div class="tile-count">${child.groupCount()} groups</div>
            </a>
        @endfor
    </div>
</div>
