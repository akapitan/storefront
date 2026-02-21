@import com.storefront.catalog.CatalogApi.CategorySection
@import java.util.List

@param List<CategorySection> sections = java.util.List.of()

@template.layouts.main(
    title = "Home",
    content = @`
        @template.home.content(sections = sections)
    `
)
