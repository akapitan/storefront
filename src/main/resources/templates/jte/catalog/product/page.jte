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

@template.layouts.main(
    title = group.name(),
    content = @`
        @template.catalog.product.content(
            group = group,
            columns = columns,
            breadcrumb = breadcrumb,
            skuRows = skuRows,
            facets = facets
        )
    `
)
