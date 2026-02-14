<header class="site-header">
    <!-- Utility Bar (Yellow top bar) -->
    <div class="utility-bar">
        <div class="container">
            <a href="#">Help</a>
            <a href="#">Contact Us</a>
            <a href="#">Account</a>
            <a href="#">Order History</a>
            <a href="#">Cart (0)</a>
        </div>
    </div>

    <!-- Main Header -->
    <div class="header-main">
        <div class="container">
            <!-- Logo -->
            <a href="/"
               class="site-logo"
               hx-get="/"
               hx-target="#main-content"
               hx-push-url="true">McMaster-Carr</a>

            <!-- Search Bar -->
            <div class="search-bar">
                <form method="get" action="/catalog/search"
                      hx-get="/catalog/search"
                      hx-target="#main-content"
                      hx-trigger="submit"
                      hx-push-url="true">
                    <input type="search"
                           name="q"
                           class="search-input"
                           placeholder="Search for products..."
                           autocomplete="off"/>
                    <button type="submit" class="btn btn-primary">Search</button>
                </form>
            </div>

            <!-- Quick Links -->
            <nav>
                <ul class="nav-links">
                    <li><a href="/"
                           hx-get="/"
                           hx-target="#main-content"
                           hx-push-url="true">Home</a></li>
                    <li><a href="/catalog"
                           hx-get="/catalog"
                           hx-target="#main-content"
                           hx-push-url="true">Products</a></li>
                </ul>
            </nav>
        </div>
    </div>
</header>

