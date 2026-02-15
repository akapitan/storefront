@import com.storefront.catalog.CatalogApi.CategoryNode
@import com.storefront.catalog.CatalogApi.CategoryGroup
@import java.util.List

@param CategoryNode category
@param List<CategoryGroup> groups = java.util.List.of()

<div class="mcm-expanded-category">
    <div class="mcm-expanded-header">
        <a href="/"
           class="mcm-back-link"
           hx-get="/"
           hx-target="#main-content"
           hx-push-url="true">&larr; All Categories</a>
        <h1 class="mcm-expanded-title">${category.name()}</h1>
    </div>

    @if(groups.isEmpty())
        <p class="text-muted">No subcategories found.</p>
    @else
        <div class="mcm-subcategory-columns">
            @for(var group : groups)
                <div class="mcm-subcategory-group">
                    <div class="mcm-group-header">
                        @if(group.items().isEmpty())
                            <a href="/catalog/category/${group.header().slug()}"
                               hx-get="/catalog/category/${group.header().slug()}"
                               hx-target="#main-content"
                               hx-push-url="true">${group.header().name()}</a>
                        @else
                            ${group.header().name()}
                        @endif
                    </div>
                    @if(!group.items().isEmpty())
                        <ul class="mcm-group-items">
                            @for(var item : group.items())
                                <li>
                                    <a href="/catalog/category/${item.slug()}"
                                       hx-get="/catalog/category/${item.slug()}"
                                       hx-target="#main-content"
                                       hx-push-url="true">${item.name()}</a>
                                </li>
                            @endfor
                        </ul>
                    @endif
                </div>
            @endfor
        </div>
    @endif
</div>
