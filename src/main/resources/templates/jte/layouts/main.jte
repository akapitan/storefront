@import gg.jte.Content

@param String title
@param Content content

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
        <!-- Left Sidebar - Category Navigation -->
        @template.fragments.sidebar()

        <!-- Main Content Area -->
        <div class="main-content" id="main-content">
            ${content}
        </div>
    </div>
</main>

<!-- Footer -->
@template.fragments.footer()

<!-- Sidebar Toggle Script -->
<script>
    function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        sidebar.classList.toggle('collapsed');

        // Save state to localStorage
        const isCollapsed = sidebar.classList.contains('collapsed');
        localStorage.setItem('sidebarCollapsed', isCollapsed);
    }

    // Restore sidebar state on page load
    document.addEventListener('DOMContentLoaded', function () {
        const sidebarCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
        if (sidebarCollapsed) {
            document.getElementById('sidebar').classList.add('collapsed');
        }
    });
</script>


</body>
</html>

