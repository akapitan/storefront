@import com.storefront.catalog.ProductApi.ProductGroupDetail
@import com.storefront.catalog.CategoryApi.CategoryBreadcrumb
@import com.storefront.catalog.ProductApi.ColumnConfig
@import com.storefront.catalog.ProductApi.SkuRow
@import com.storefront.catalog.ProductApi.FacetGroup
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
