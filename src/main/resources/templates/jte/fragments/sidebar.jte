<aside class="sidebar" id="sidebar">
    <!-- Toggle Button -->
    <button class="sidebar-toggle"
            onclick="toggleSidebar()"
            aria-label="Toggle sidebar"
            title="Toggle navigation"></button>

    <nav class="category-nav">
        <h2 class="category-nav-title">Product Categories</h2>
        <ul class="category-tree">
            <li>
                <a hx-get="/catalog/category/696bc45d-e641-4dd0-b51a-2f019750ee6a"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Fasteners
                    <span class="category-count">(1,234)</span>
                </a>
                <ul>
                    <li><a href="#"
                           hx-get="/catalog/category/screws"
                           hx-target="#main-content"
                           hx-push-url="true">Screws <span class="category-count">(456)</span></a></li>
                    <li><a href="#"
                           hx-get="/catalog/category/bolts"
                           hx-target="#main-content"
                           hx-push-url="true">Bolts <span class="category-count">(389)</span></a></li>
                    <li><a href="#"
                           hx-get="/catalog/category/nuts"
                           hx-target="#main-content"
                           hx-push-url="true">Nuts <span class="category-count">(234)</span></a></li>
                    <li><a href="#"
                           hx-get="/catalog/category/washers"
                           hx-target="#main-content"
                           hx-push-url="true">Washers <span class="category-count">(155)</span></a></li>
                </ul>
            </li>
            <li>
                <a href="/catalog/category/hardware"
                   hx-get="/catalog/category/hardware"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Hardware
                    <span class="category-count">(892)</span>
                </a>
                <ul>
                    <li><a href="#"
                           hx-get="/catalog/category/hinges"
                           hx-target="#main-content"
                           hx-push-url="true">Hinges <span class="category-count">(167)</span></a></li>
                    <li><a href="#"
                           hx-get="/catalog/category/brackets"
                           hx-target="#main-content"
                           hx-push-url="true">Brackets <span class="category-count">(234)</span></a></li>
                    <li><a href="#"
                           hx-get="/catalog/category/handles"
                           hx-target="#main-content"
                           hx-push-url="true">Handles <span class="category-count">(123)</span></a></li>
                </ul>
            </li>
            <li>
                <a href="/catalog/category/tools"
                   hx-get="/catalog/category/tools"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Tools
                    <span class="category-count">(2,456)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/electrical"
                   hx-get="/catalog/category/electrical"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Electrical
                    <span class="category-count">(1,567)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/plumbing"
                   hx-get="/catalog/category/plumbing"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Plumbing
                    <span class="category-count">(987)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/safety"
                   hx-get="/catalog/category/safety"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Safety Equipment
                    <span class="category-count">(654)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/adhesives"
                   hx-get="/catalog/category/adhesives"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Adhesives & Sealants
                    <span class="category-count">(423)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/material-handling"
                   hx-get="/catalog/category/material-handling"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Material Handling
                    <span class="category-count">(756)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/pneumatics"
                   hx-get="/catalog/category/pneumatics"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Pneumatics & Hydraulics
                    <span class="category-count">(1,123)</span>
                </a>
            </li>
            <li>
                <a href="/catalog/category/power-transmission"
                   hx-get="/catalog/category/power-transmission"
                   hx-target="#main-content"
                   hx-push-url="true">
                    Power Transmission
                    <span class="category-count">(845)</span>
                </a>
            </li>
        </ul>
    </nav>
</aside>

