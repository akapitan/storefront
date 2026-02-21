@import gg.jte.Content

@param String title
@param Content content
@param Content sidebarContent = null

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>${title} - Storefront</title>

    <!-- Stylesheet -->
    <link rel="stylesheet" href="/css/main.css"/>

    <!-- HTMX for dynamic content loading -->
    <script src="https://unpkg.com/htmx.org@2.0.0" defer></script>

    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="/favicon.ico"/>
</head>
<body>

<!-- Navigation -->
@template.fragments.nav()

<!-- Main Content Layout -->
<main>
    <div class="page-layout">
        <!-- Left Sidebar -->
        <aside class="sidebar" id="sidebar">
            <div id="sidebar-content">
                @if(sidebarContent != null)
                    ${sidebarContent}
                @else
                    <nav class="category-nav">
                        <h2 class="category-nav-title">Product Categories</h2>
                        <ul class="category-tree" id="category-tree"
                            hx-get="/catalog/categories/top-level"
                            hx-trigger="load"
                            hx-swap="innerHTML">
                            <li class="text-muted">Loading categories...</li>
                        </ul>
                    </nav>
                @endif
            </div>
        </aside>

        <!-- Main Content Area -->
        <div class="main-content" id="main-content">
            ${content}
        </div>
    </div>
</main>

<!-- Footer -->
@template.fragments.footer()

<script>
    // Close search dropdown when clicking outside
    document.addEventListener('click', function(e) {
        const searchBar = document.querySelector('.search-bar');
        const searchDropdown = document.getElementById('search-dropdown');

        if (searchBar && searchDropdown && !searchBar.contains(e.target)) {
            searchDropdown.innerHTML = '';
        }
    });

    // Close search dropdown on ESC key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            const searchDropdown = document.getElementById('search-dropdown');
            if (searchDropdown) {
                searchDropdown.innerHTML = '';
            }
        }
    });

    // Clear search dropdown when input is empty
    document.addEventListener('DOMContentLoaded', function() {
        const searchInput = document.querySelector('.search-input');
        const searchDropdown = document.getElementById('search-dropdown');

        if (searchInput && searchDropdown) {
            searchInput.addEventListener('input', function() {
                if (this.value.trim() === '') {
                    searchDropdown.innerHTML = '';
                }
            });
        }
    });

    // Active category highlighting
    function updateActiveCategory() {
        const path = location.pathname;
        document.querySelectorAll('.category-tree a').forEach(function(link) {
            if (link.getAttribute('href') === path) {
                link.classList.add('active');
            } else {
                link.classList.remove('active');
            }
        });
    }

    document.addEventListener('DOMContentLoaded', updateActiveCategory);
    document.body.addEventListener('htmx:pushedIntoHistory', updateActiveCategory);
    document.body.addEventListener('htmx:afterSwap', updateActiveCategory);
</script>


</body>
</html>
