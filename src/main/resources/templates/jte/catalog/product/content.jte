@import com.storefront.catalog.CatalogApi.ProductGroupDetail
@import com.storefront.catalog.CatalogApi.CategoryBreadcrumb
@import com.storefront.catalog.CatalogApi.ColumnConfig
@import com.storefront.catalog.CatalogApi.SkuRow
@import com.storefront.catalog.CatalogApi.FacetGroup
@import java.util.List

@param ProductGroupDetail group
@param List<ColumnConfig> columns
@param List<CategoryBreadcrumb> breadcrumb
@param List<SkuRow> skuRows
@param List<FacetGroup> facets

<div class="product-group-page">
    <%-- Breadcrumb --%>
    <nav class="breadcrumb">
        <a href="/" hx-get="/" hx-target="#main-content" hx-push-url="true">Home</a>
        @for(var crumb : breadcrumb)
            / <a href="/catalog/category/${crumb.slug()}"
                 hx-get="/catalog/category/${crumb.slug()}"
                 hx-target="#main-content"
                 hx-push-url="true">${crumb.name()}</a>
        @endfor
        / <span>${group.name()}</span>
    </nav>

    <%-- Header --%>
    <div class="pg-header">
        <div class="pg-header-text">
            <h1 class="pg-title">${group.name()}</h1>
            @if(group.subtitle() != null)
                <p class="pg-subtitle">${group.subtitle()}</p>
            @endif
            @if(group.description() != null)
                <p class="pg-description">${group.description()}</p>
            @endif
        </div>
        <div class="pg-header-images">
            @if(group.overviewImageUrl() != null)
                <img src="${group.overviewImageUrl()}" alt="${group.name()}" class="pg-overview-image"/>
            @endif
            @if(group.diagramImageUrl() != null)
                <img src="${group.diagramImageUrl()}" alt="${group.name()} dimensions" class="pg-diagram-image"/>
            @endif
        </div>
    </div>

    @if(group.engineeringNote() != null)
        <div class="pg-engineering-note">
            <strong>Note:</strong> ${group.engineeringNote()}
        </div>
    @endif

    <%-- Main content: filter panel + variant table --%>
    <div class="pg-body">
        <%-- Filter panel (left rail) --%>
        <div class="filter-panel" id="filter-panel">
            @template.catalog.product.filter-panel(
                group = group,
                facets = facets
            )
        </div>

        <%-- Variant table --%>
        <div class="variant-table-container" id="variant-table-container">
            <div class="variant-table-header">
                <span class="variant-count">${skuRows.size()} items</span>
            </div>
            @template.catalog.product.variant-table(
                group = group,
                columns = columns,
                skuRows = skuRows
            )
        </div>
    </div>
</div>
