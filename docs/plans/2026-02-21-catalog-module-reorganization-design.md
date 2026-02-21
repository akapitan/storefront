# Catalog Module Reorganization — Design

## Problem

The catalog module has three pain points:

1. **God API** — `CatalogApi` has 18 methods and 10 projection records covering categories, products, SKUs, search, attributes, and cross-module checks.
2. **Blob service** — `ProductGroupService` implements all 18 methods, even though they cover unrelated concerns.
3. **Inconsistent naming** — `domain/model/` follows hexagonal convention, but `group/` and `product/` packages don't map to any architectural layer.

## Approach: Vertical Slices Within Hexagonal Layers

Split `CatalogApi` into three focused sub-interfaces, split the service and controller accordingly, and align package names to the hexagonal convention documented in CLAUDE.md. Catalog remains **one** Spring Modulith module.

## Sub-API Interfaces

### `CategoryApi` (6 methods, 4 records)

```
findTopLevelCategories()           → List<CategoryNode>
findChildCategories(parentId)      → List<CategoryNode>
findBreadcrumb(categoryPath)       → List<CategoryBreadcrumb>
findCategoryBySlug(slug)           → Optional<CategoryNode>
findCategoryDescendants(path)      → List<CategoryNode>
findAllCategoriesGrouped()         → List<CategorySection>
```

Records: `CategoryNode`, `CategoryGroup`, `CategorySection`, `CategoryBreadcrumb`

### `ProductApi` (10 methods, 9 records)

```
browseByCategory(path, request)    → Slice<ProductGroupSummary>
findProductGroupBySlug(slug)       → Optional<ProductGroupDetail>
findVariantTable(groupId, skuIds)  → List<SkuRow>
findMatchingSkuIds(groupId, ...)   → List<UUID>
findSkuByPartNumber(partNumber)    → Optional<SkuRow>
findColumnConfig(groupId)          → List<ColumnConfig>
findFacetCounts(groupId, skuIds)   → List<FacetGroup>
findFilterableAttributes(catId)    → List<AttributeSummary>
skuExistsAndActive(skuId)          → boolean
findSkuPriceInfo(skuId, qty)       → Optional<SkuPriceInfo>
```

Records: `ProductGroupSummary`, `ProductGroupDetail`, `SkuRow`, `ColumnConfig`, `FacetGroup`, `FacetOption`, `NumericRange`, `SkuPriceInfo`, `AttributeSummary`

### `SearchApi` (2 methods, no own records)

```
search(query, request)             → Pagination<ProductApi.ProductGroupSummary>
searchDropdown(query, limit)       → List<ProductApi.ProductGroupSummary>
```

Returns `ProductApi.ProductGroupSummary` — no duplication.

### `CatalogApi` — Deleted

No facade. Sub-APIs are the public contract. Cross-module consumers inject the specific sub-API they need (e.g., Cart imports `ProductApi` for `findSkuPriceInfo`).

## Controller Split

| Controller | Routes | Injects |
|---|---|---|
| `CategoryController` | `/catalog/categories/top-level`, `/catalog/category/{slug}`, `/catalog/category/{slug}/children` | `CategoryApi`, `ProductApi` |
| `ProductController` | `/catalog/product/{slug}`, `/catalog/product/{slug}/filter` | `ProductApi`, `CategoryApi` |
| `SearchController` | `/catalog/search/dropdown`, `/catalog/search` | `SearchApi` |

Exceptions move to their owning controller: `CategoryNotFoundException` → `CategoryController`, `ProductGroupNotFoundException` → `ProductController`. `parseFilterParams` stays with `ProductController`.

## Service Split

| Service | Implements | Injects |
|---|---|---|
| `CategoryService` | `CategoryApi` | `CategoryRepository` |
| `ProductGroupService` | `ProductApi` | `ProductGroupRepository`, `SkuRepository`, `AttributeRepository` |
| `SearchService` | `SearchApi` | `ProductGroupRepository` |

All methods `@Transactional(readOnly = true)`.

## Final Package Layout

```
catalog/
├── CategoryApi.java                   # 6 methods + 4 records
├── ProductApi.java                    # 10 methods + 9 records
├── SearchApi.java                     # 2 methods, returns ProductApi.ProductGroupSummary
│
├── interfaces/
│   ├── CategoryController.java        # /catalog/category/*, /catalog/categories/*
│   ├── ProductController.java         # /catalog/product/*
│   └── SearchController.java          # /catalog/search/*
│
├── application/
│   ├── CategoryService.java           # implements CategoryApi
│   ├── ProductGroupService.java       # implements ProductApi
│   └── SearchService.java             # implements SearchApi
│
├── domain/
│   └── model/
│       ├── CategoryRepository.java
│       ├── ProductGroupRepository.java
│       ├── SkuRepository.java
│       └── AttributeRepository.java
│
└── infrastructure/
    ├── JooqCategoryRepository.java
    ├── JooqProductGroupRepository.java
    ├── JooqSkuRepository.java
    └── JooqAttributeRepository.java
```

## What Changes

- `CatalogApi.java` → deleted, replaced by `CategoryApi`, `ProductApi`, `SearchApi`
- `group/ProductGroupService.java` → split into `application/{CategoryService, ProductGroupService, SearchService}`
- `product/ProductController.java` → split into `interfaces/{CategoryController, ProductController, SearchController}`
- `group/` and `product/` packages → deleted

## What Stays the Same

- `domain/model/` — 4 repository interfaces, untouched
- `infrastructure/` — 4 jOOQ implementations, untouched (import paths for `CatalogApi.*` records change to `ProductApi.*` / `CategoryApi.*`)
- All JTE templates — no changes
- All HTTP routes — same URLs, served by different controllers
- Cross-module consumers — update imports from `CatalogApi` to specific sub-API

## Risks

- **Import churn** — anything referencing `CatalogApi.ProductGroupSummary` etc. must update imports. Grep for `CatalogApi` across all modules.
- **Spring Modulith verification** — sub-APIs must remain `public` at the module root package for cross-module visibility. Services and controllers remain package-private in their sub-packages.
