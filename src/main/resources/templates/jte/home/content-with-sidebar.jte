@import com.storefront.catalog.CatalogApi.CategorySection
@import java.util.List

@param List<CategorySection> sections = java.util.List.of()

<%-- Main content --%>
@template.home.content(sections = sections)

<%-- OOB sidebar swap — restore category navigation --%>
<div id="sidebar-content" hx-swap-oob="innerHTML:#sidebar-content">
    @template.fragments.sidebar()
</div>
