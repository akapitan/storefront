@import com.storefront.catalog.CatalogApi.CategoryNode
@import java.util.List

@param List<CategoryNode> categories

@for(var cat : categories)
    <li>
        <a href="/catalog/category/${cat.slug()}"
           hx-get="/catalog/category/${cat.slug()}"
           hx-target="#main-content"
           hx-push-url="true">
            ${cat.name()}
            <span class="category-count">(${cat.groupCount()})</span>
        </a>
        @if(!cat.isLeaf())
            <button class="category-expand"
                    hx-get="/catalog/category/${cat.slug()}/children"
                    hx-target="next ul"
                    hx-swap="innerHTML"
                    onclick="this.style.display='none'">+</button>
            <ul class="category-tree"></ul>
        @endif
    </li>
@endfor
