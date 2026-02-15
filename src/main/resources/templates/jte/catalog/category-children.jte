@import com.storefront.catalog.CatalogApi.CategoryNode
@import java.util.List

@param List<CategoryNode> children

@for(var child : children)
    <li>
        <a href="/catalog/category/${child.slug()}"
           hx-get="/catalog/category/${child.slug()}"
           hx-target="#main-content"
           hx-push-url="true">
            ${child.name()}
            <span class="category-count">(${child.groupCount()})</span>
        </a>
        @if(!child.isLeaf())
            <button class="category-expand"
                    hx-get="/catalog/category/${child.slug()}/children"
                    hx-target="next ul"
                    hx-swap="innerHTML">+</button>
            <ul class="category-tree"></ul>
        @endif
    </li>
@endfor
