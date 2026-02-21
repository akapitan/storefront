@import com.storefront.catalog.CategoryApi.CategoryNode
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
    </li>
@endfor
