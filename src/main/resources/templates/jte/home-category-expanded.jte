@import com.storefront.catalog.CatalogApi.CategoryNode
@import com.storefront.catalog.CatalogApi.CategoryGroup
@import java.util.List

@param CategoryNode category
@param List<CategoryGroup> groups = java.util.List.of()

@template.layouts.main(
    title = category.name(),
    content = @`
        @template.home-category-expanded-content(category = category, groups = groups)
    `
)
