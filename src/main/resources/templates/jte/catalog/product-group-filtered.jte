@import com.storefront.catalog.CatalogApi.ProductGroupDetail
@import com.storefront.catalog.CatalogApi.ColumnConfig
@import com.storefront.catalog.CatalogApi.SkuRow
@import com.storefront.catalog.CatalogApi.FacetGroup
@import java.util.List

@param ProductGroupDetail group
@param List<ColumnConfig> columns
@param List<SkuRow> skuRows
@param List<FacetGroup> facets

<%-- This template is returned by the HTMX filter endpoint --%>
<%-- It replaces the variant-table-container content --%>
<div class="variant-table-header">
    <span class="variant-count">${skuRows.size()} items</span>
</div>
@template.catalog.variant-table(
    group = group,
    columns = columns,
    skuRows = skuRows
)
