@import com.storefront.catalog.CategoryApi.CategoryNode
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
    </li>
@endfor
