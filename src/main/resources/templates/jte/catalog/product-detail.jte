@import com.storefront.catalog.CatalogApi.ProductDetail
@import com.fasterxml.jackson.databind.JsonNode

@param ProductDetail product

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>${product.name()} - Storefront</title>
    <link rel="stylesheet" href="/css/main.css"/>
    <script src="https://unpkg.com/htmx.org@2.0.0" defer></script>
</head>
<body>

@template.fragments.nav()

<main>
    <div class="container">
        @template.catalog.product-detail-content(product = product)
    </div>
</main>

@template.fragments.footer()

</body>
</html>

