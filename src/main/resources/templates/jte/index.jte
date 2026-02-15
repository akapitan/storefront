@import com.storefront.catalog.CatalogApi.CategoryNode
@import java.util.List

@param List<CategoryNode> categories = java.util.List.of()

@template.layouts.main(
    title = "Home",
    content = @`
        @template.home-content(categories = categories)
    `
)
