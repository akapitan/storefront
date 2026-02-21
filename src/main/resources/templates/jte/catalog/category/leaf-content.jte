@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.CategoryApi.CategoryNode
@import com.storefront.catalog.CategoryApi.LeafGroupTable
@import com.storefront.catalog.ProductApi.ColumnConfig
@import com.storefront.catalog.ProductApi.SkuRow
@import com.storefront.shared.web.TemplateHelpers
@import java.util.List
@import java.util.Map

@param CategoryNode category
@param List<CategoryBreadcrumb> breadcrumb
@param List<LeafGroupTable> groupTables
@param Map<Integer, List<Integer>> enumFilters
@param Map<Integer, ?> rangeFilters

<div class="category-browse leaf-browse">
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

    @if(groupTables.isEmpty())
        <div class="empty-state">No products match your current filters.</div>
    @else
        @for(var gt : groupTables)
            <section class="product-group-section">
                <h2 class="group-section-title">
                    <a href="/catalog/product/${gt.groupSlug()}"
                       hx-get="/catalog/product/${gt.groupSlug()}"
                       hx-target="#main-content"
                       hx-push-url="true">${gt.groupName()}</a>
                </h2>

                <div class="variant-table-wrapper">
                    <table class="variant-table">
                        <thead>
                            <tr>
                                @for(var col : gt.columns())
                                    @if(!col.role().equals("filter_only"))
                                        <th style="width:${col.widthPx()}px">${col.header()}</th>
                                    @endif
                                @endfor
                                <th>Part #</th>
                                <th>Price</th>
                                <th>Stock</th>
                            </tr>
                        </thead>
                        <tbody>
                            @for(var sku : gt.rows())
                                <tr>
                                    @for(var col : gt.columns())
                                        @if(!col.role().equals("filter_only"))
                                            <td>${TemplateHelpers.getSpec(sku.specsJson(), col.key())}</td>
                                        @endif
                                    @endfor
                                    <td class="part-number">${sku.partNumber()}</td>
                                    <td class="price">
                                        @if(sku.price1ea() != null)
                                            ${TemplateHelpers.formatCurrency(sku.price1ea())}
                                        @endif
                                    </td>
                                    <td class="stock">
                                        @if(sku.inStock())
                                            <span class="in-stock">In Stock</span>
                                        @else
                                            <span class="out-of-stock">Out of Stock</span>
                                        @endif
                                    </td>
                                </tr>
                            @endfor
                        </tbody>
                    </table>
                </div>
            </section>
        @endfor
    @endif
</div>
