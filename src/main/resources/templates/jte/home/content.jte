@import com.storefront.catalog.CategoryApi.CategorySection
@import java.util.List

@param List<CategorySection> sections = java.util.List.of()

<div class="mcm-directory">
    @for(var section : sections)
        <div class="mcm-directory-section">
            <h2 class="mcm-section-header">
                <a href="/catalog/category/${section.topLevel().slug()}"
                   hx-get="/catalog/category/${section.topLevel().slug()}"
                   hx-target="#main-content"
                   hx-push-url="true">${section.topLevel().name()}</a>
            </h2>

            @for(var group : section.groups())
                <div class="mcm-subgroup">
                    @if(group.items().isEmpty())
                        <%-- Depth-1 with no children: make it a direct link --%>
                        <h3 class="mcm-subgroup-header">
                            <a href="/catalog/category/${group.header().slug()}"
                               hx-get="/catalog/category/${group.header().slug()}"
                               hx-target="#main-content"
                               hx-push-url="true">${group.header().name()}</a>
                        </h3>
                    @else
                        <h3 class="mcm-subgroup-header">${group.header().name()}</h3>
                        <div class="mcm-tile-row">
                            @for(var item : group.items())
                                <a href="/catalog/category/${item.slug()}"
                                   class="mcm-tile"
                                   hx-get="/catalog/category/${item.slug()}"
                                   hx-target="#main-content"
                                   hx-push-url="true">
                                    <div class="mcm-tile-icon">
                                        <svg viewBox="0 0 48 48" width="48" height="48" xmlns="http://www.w3.org/2000/svg">
                                            <rect x="4" y="4" width="40" height="40" rx="4"
                                                  fill="#f0f0f0" stroke="#cccccc" stroke-width="1"/>
                                            <circle cx="24" cy="20" r="8" fill="#cccccc"/>
                                            <rect x="12" y="32" width="24" height="4" rx="2" fill="#cccccc"/>
                                        </svg>
                                    </div>
                                    <span class="mcm-tile-label">${item.name()}</span>
                                </a>
                            @endfor
                        </div>
                    @endif
                </div>
            @endfor
        </div>
    @endfor
</div>
