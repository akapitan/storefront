# Template Reorganization: URL-Mapped Structure

## Goal

Reorganize the flat `catalog/` template directory into subdirectories that mirror URL routes, so the file tree shows which endpoint each template belongs to.

## Proposed Structure

```
templates/jte/
├── home/
│   ├── page.jte                       # GET /           (full page)
│   ├── content.jte                    # home body block
│   └── content-with-sidebar.jte       # GET /           (HTMX)
├── catalog/
│   ├── category/
│   │   ├── page.jte                   # GET /catalog/category/{slug}           (full page)
│   │   ├── content.jte                # category body block
│   │   ├── content-with-sidebar.jte   # GET /catalog/category/{slug}           (HTMX)
│   │   ├── children.jte              # GET /catalog/category/{slug}/children
│   │   ├── filter-sidebar.jte        # sidebar filter fragment
│   │   └── top-level.jte             # GET /catalog/categories/top-level
│   ├── product/
│   │   ├── page.jte                   # GET /catalog/product/{slug}            (full page)
│   │   ├── content.jte                # GET /catalog/product/{slug}            (HTMX)
│   │   ├── filtered.jte              # GET /catalog/product/{slug}/filter
│   │   ├── filter-panel.jte          # filter panel fragment
│   │   ├── filter-facet.jte          # single facet fragment
│   │   └── variant-table.jte         # SKU table fragment
│   └── search/
│       ├── page.jte                   # GET /catalog/search                    (full page)
│       ├── content.jte                # GET /catalog/search                    (HTMX)
│       ├── dropdown.jte              # GET /catalog/search/dropdown
│       └── dropdown-empty.jte        # dropdown empty state
├── fragments/                         # unchanged
├── layouts/                           # unchanged
└── .jteroot
```

## Changes Required

### 1. Move & rename 19 template files

| Old path | New path |
|----------|----------|
| `index.jte` | `home/page.jte` |
| `home-content.jte` | `home/content.jte` |
| `home-content-with-sidebar.jte` | `home/content-with-sidebar.jte` |
| `catalog/category-browse.jte` | `catalog/category/page.jte` |
| `catalog/category-browse-content.jte` | `catalog/category/content.jte` |
| `catalog/category-browse-content-with-sidebar.jte` | `catalog/category/content-with-sidebar.jte` |
| `catalog/category-children.jte` | `catalog/category/children.jte` |
| `catalog/category-filter-sidebar.jte` | `catalog/category/filter-sidebar.jte` |
| `catalog/top-level-categories.jte` | `catalog/category/top-level.jte` |
| `catalog/product-group.jte` | `catalog/product/page.jte` |
| `catalog/product-group-content.jte` | `catalog/product/content.jte` |
| `catalog/product-group-filtered.jte` | `catalog/product/filtered.jte` |
| `catalog/filter-panel.jte` | `catalog/product/filter-panel.jte` |
| `catalog/filter-facet.jte` | `catalog/product/filter-facet.jte` |
| `catalog/variant-table.jte` | `catalog/product/variant-table.jte` |
| `catalog/search-results.jte` | `catalog/search/page.jte` |
| `catalog/search-results-content.jte` | `catalog/search/content.jte` |
| `catalog/search-dropdown.jte` | `catalog/search/dropdown.jte` |
| `catalog/search-dropdown-empty.jte` | `catalog/search/dropdown-empty.jte` |

### 2. Update `@template.*` references in templates

| Old reference | New reference |
|---------------|---------------|
| `@template.home-content(...)` | `@template.home.content(...)` |
| `@template.catalog.category-browse-content(...)` | `@template.catalog.category.content(...)` |
| `@template.catalog.category-filter-sidebar(...)` | `@template.catalog.category.filter-sidebar(...)` |
| `@template.catalog.search-results-content(...)` | `@template.catalog.search.content(...)` |
| `@template.catalog.product-group-content(...)` | `@template.catalog.product.content(...)` |
| `@template.catalog.filter-panel(...)` | `@template.catalog.product.filter-panel(...)` |
| `@template.catalog.filter-facet(...)` | `@template.catalog.product.filter-facet(...)` |
| `@template.catalog.variant-table(...)` | `@template.catalog.product.variant-table(...)` |

`@template.fragments.*` and `@template.layouts.*` are unchanged.

### 3. Update controller return strings

**HomeController:**
- `"index"` → `"home/page"`
- `"home-content-with-sidebar"` → `"home/content-with-sidebar"`

**ProductController:**
- `"catalog/top-level-categories"` → `"catalog/category/top-level"`
- `"catalog/category-browse"` → `"catalog/category/page"`
- `"catalog/category-browse-content-with-sidebar"` → `"catalog/category/content-with-sidebar"`
- `"catalog/category-children"` → `"catalog/category/children"`
- `"catalog/product-group"` → `"catalog/product/page"`
- `"catalog/product-group-content"` → `"catalog/product/content"`
- `"catalog/product-group-filtered"` → `"catalog/product/filtered"`
- `"catalog/search-dropdown-empty"` → `"catalog/search/dropdown-empty"`
- `"catalog/search-dropdown"` → `"catalog/search/dropdown"`
- `"catalog/search-results"` → `"catalog/search/page"`
- `"catalog/search-results-content"` → `"catalog/search/content"`

## What doesn't change

- No Java logic, model attributes, or URL routing
- No HTML/CSS
- No build config
- `fragments/` and `layouts/` stay in place