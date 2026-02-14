@import com.storefront.catalog.CatalogApi.ProductSummary

</html>
</body>

@template.fragments.footer()

</main>
    </div>
        )
            query = query
            hasPrev = hasPrev,
            hasNext = hasNext,
            currentPage = currentPage,
            totalPages = totalPages,
            totalItems = totalItems,
            results = results,
        @template.catalog.search-results-content(
    <div class="container">
<main>

@template.fragments.nav()

<body>
</head>
    <script src="https://unpkg.com/htmx.org@2.0.0" defer></script>
    <link rel="stylesheet" href="/css/main.css"/>
    <title>Search Results - Storefront</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta charset="UTF-8"/>
<head>
<html lang="en">
<!DOCTYPE html>

@param String query
@param boolean hasPrev
@param boolean hasNext
@param int currentPage
@param int totalPages
@param long totalItems
@param List<ProductSummary> results

@import java.util.List
