@import com.storefront.catalog.CatalogApi.ProductSummary
@import java.util.List
@import java.util.UUID

@param UUID categoryId
@param List<ProductSummary> products
@param boolean hasMore
@param int nextPage
@param String sort

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Products - Storefront</title>
    <link rel="stylesheet" href="/css/main.css"/>
    <script src="https://unpkg.com/htmx.org@2.0.0" defer></script>
</head>
<body>

@template.fragments.nav()

<main>
    <div class="container">
        @template.catalog.product-grid-content(
            categoryId = categoryId,
            products = products,
            hasMore = hasMore,
            nextPage = nextPage,
            sort = sort
        )
    </div>
</main>

@template.fragments.footer()

</body>
</html>

