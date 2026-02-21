@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.ProductApi.ProductGroupSummary
@import java.util.List

@param CategoryNode category
@param List<ProductGroupSummary> groups
@param boolean hasMore
@param int nextPage
@param List<CategoryNode> children
@param List<CategoryBreadcrumb> breadcrumb

<div class="category-browse">
    <%-- Breadcrumb --%>
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
    <p class="text-muted">${category.groupCount()} product groups</p>

    <%-- Subcategories --%>
    @if(!children.isEmpty())
        <div class="subcategory-chips">
            @for(var child : children)
                <a href="/catalog/category/${child.slug()}"
                   class="subcategory-chip"
                   hx-get="/catalog/category/${child.slug()}"
                   hx-target="#main-content"
                   hx-push-url="true">
                    ${child.name()}
                    <span class="chip-count">(${child.groupCount()})</span>
                </a>
            @endfor
        </div>
    @endif

    <%-- Product group cards --%>
    <div class="product-group-grid" id="product-group-grid">
        @if(!groups.isEmpty())
            @for(int i = 0; i < groups.size(); i++)
                !{var group = groups.get(i);}
                !{var isLast = i == groups.size() - 1;}
                <a href="/catalog/product/${group.slug()}"
                   class="product-group-card"
                   hx-get="/catalog/product/${group.slug()}"
                   hx-target="#main-content"
                   hx-push-url="true">

                    @if(isLast && hasMore)
                        <div hx-get="/catalog/category/${category.slug()}?page=${nextPage}"
                             hx-trigger="revealed"
                             hx-target="#product-group-grid"
                             hx-swap="beforeend">
                        </div>
                    @endif

                    @if(group.overviewImageUrl() != null)
                        <img src="${group.overviewImageUrl()}"
                             alt="${group.name()}"
                             class="group-card-image"
                             loading="lazy"/>
                    @else
                        <div class="group-card-image-placeholder">No Image</div>
                    @endif

                    <div class="group-card-info">
                        <div class="group-card-name">${group.name()}</div>
                        @if(group.subtitle() != null)
                            <div class="group-card-subtitle">${group.subtitle()}</div>
                        @endif
                        <div class="group-card-meta">
                            <span class="group-card-sku-count">${group.skuCount()} options</span>
                            @if(group.minPriceUsd() != null)
                                <span class="group-card-price">from ${com.storefront.shared.web.TemplateHelpers.formatCurrency(group.minPriceUsd())}</span>
                            @endif
                            @if(group.anyInStock())
                                <span class="group-card-stock in-stock">In Stock</span>
                            @else
                                <span class="group-card-stock out-of-stock">Out of Stock</span>
                            @endif
                        </div>
                    </div>
                </a>
            @endfor
        @else
            <div class="empty-state">No product groups found in this category.</div>
        @endif
    </div>
</div>
