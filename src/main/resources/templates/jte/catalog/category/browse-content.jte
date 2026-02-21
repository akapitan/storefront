@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.CategoryApi.FilteredCategory
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param List<CategoryBreadcrumb> breadcrumb
@param List<FilteredCategory> children
@param Map<Integer, List<Integer>> enumFilters
@param Map<Integer, ?> rangeFilters

<div class="category-browse">
    <nav class="breadcrumb">
        <a href="/" hx-get="/" hx-target="#main-content" hx-push-url="true">Home</a>
        @for(var crumb : breadcrumb)
            / <a href="/catalog/category/${crumb.slug()}"
                 hx-get="/catalog/category/${crumb.slug()}"
                 hx-target="#main-content"
                 hx-push-url="true">${crumb.name()}</a>
        @endfor
        / <span>${category.name()}</span>
    </nav>

    <h1 class="page-title">${category.name()}</h1>

    @if(children.isEmpty())
        <div class="empty-state">No subcategories match your current filters.</div>
    @else
        <div class="subcategory-list">
            @for(var child : children)
                <a href="/catalog/category/${child.slug()}"
                   class="subcategory-row"
                   hx-get="/catalog/category/${child.slug()}"
                   hx-target="#main-content"
                   hx-push-url="true">
                    <span class="subcategory-name">${child.name()}</span>
                    <span class="subcategory-sku-count">${child.skuCount()} SKUs</span>
                </a>
            @endfor
        </div>
    @endif
</div>
