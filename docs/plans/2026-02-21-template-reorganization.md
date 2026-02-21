# Template Reorganization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reorganize the flat JTE template directory into subdirectories that mirror URL routes.

**Architecture:** Pure file reorganization — move 19 template files into URL-mapped subdirectories, update all `@template.*` cross-references in templates, and update controller return strings. No logic, HTML, or routing changes.

**Tech Stack:** JTE templates, Spring MVC controllers

---

### Task 0: Create directory structure

**Files:**
- Create: `src/main/resources/templates/jte/home/`
- Create: `src/main/resources/templates/jte/catalog/category/`
- Create: `src/main/resources/templates/jte/catalog/product/`
- Create: `src/main/resources/templates/jte/catalog/search/`

**Step 1: Create all new directories**

```bash
TPL=src/main/resources/templates/jte
mkdir -p $TPL/home $TPL/catalog/category $TPL/catalog/product $TPL/catalog/search
```

**Step 2: Commit**

```bash
git add -A && git commit -m "chore: create URL-mapped template directories"
```

---

### Task 1: Move home templates

**Files:**
- Move: `index.jte` → `home/page.jte`
- Move: `home-content.jte` → `home/content.jte`
- Move: `home-content-with-sidebar.jte` → `home/content-with-sidebar.jte`
- Modify: `src/main/java/com/storefront/HomeController.java:18,23`

All paths below are relative to `src/main/resources/templates/jte/`.

**Step 1: Move the 3 home templates**

```bash
TPL=src/main/resources/templates/jte
git mv $TPL/index.jte $TPL/home/page.jte
git mv $TPL/home-content.jte $TPL/home/content.jte
git mv $TPL/home-content-with-sidebar.jte $TPL/home/content-with-sidebar.jte
```

**Step 2: Update `@template.*` references in moved templates**

In `home/page.jte` (was `index.jte`), change line 9:
```
@template.home-content(sections = sections)
```
→
```
@template.home.content(sections = sections)
```

In `home/content-with-sidebar.jte`, change line 7:
```
@template.home-content(sections = sections)
```
→
```
@template.home.content(sections = sections)
```

**Step 3: Update HomeController return strings**

In `src/main/java/com/storefront/HomeController.java`:

Line 23: `"home-content-with-sidebar"` → `"home/content-with-sidebar"`
Line 25: `"index"` → `"home/page"`

**Step 4: Build to verify**

```bash
./gradlew build
```

Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add -A && git commit -m "refactor: move home templates to home/ directory"
```

---

### Task 2: Move category templates

**Files:**
- Move: `catalog/category-browse.jte` → `catalog/category/page.jte`
- Move: `catalog/category-browse-content.jte` → `catalog/category/content.jte`
- Move: `catalog/category-browse-content-with-sidebar.jte` → `catalog/category/content-with-sidebar.jte`
- Move: `catalog/category-children.jte` → `catalog/category/children.jte`
- Move: `catalog/category-filter-sidebar.jte` → `catalog/category/filter-sidebar.jte`
- Move: `catalog/top-level-categories.jte` → `catalog/category/top-level.jte`
- Modify: `src/main/java/com/storefront/catalog/product/ProductController.java`

All paths below are relative to `src/main/resources/templates/jte/`.

**Step 1: Move the 6 category templates**

```bash
TPL=src/main/resources/templates/jte
git mv $TPL/catalog/category-browse.jte $TPL/catalog/category/page.jte
git mv $TPL/catalog/category-browse-content.jte $TPL/catalog/category/content.jte
git mv $TPL/catalog/category-browse-content-with-sidebar.jte $TPL/catalog/category/content-with-sidebar.jte
git mv $TPL/catalog/category-children.jte $TPL/catalog/category/children.jte
git mv $TPL/catalog/category-filter-sidebar.jte $TPL/catalog/category/filter-sidebar.jte
git mv $TPL/catalog/top-level-categories.jte $TPL/catalog/category/top-level.jte
```

**Step 2: Update `@template.*` references in moved templates**

In `catalog/category/page.jte` (was `category-browse.jte`):

Line 18: `@template.catalog.category-browse-content(` → `@template.catalog.category.content(`
Line 28: `@template.catalog.category-filter-sidebar(` → `@template.catalog.category.filter-sidebar(`

In `catalog/category/content-with-sidebar.jte` (was `category-browse-content-with-sidebar.jte`):

Line 16: `@template.catalog.category-browse-content(` → `@template.catalog.category.content(`
Line 27: `@template.catalog.category-filter-sidebar(` → `@template.catalog.category.filter-sidebar(`

**Step 3: Update ProductController category return strings**

In `src/main/java/com/storefront/catalog/product/ProductController.java`:

Line 33: `"catalog/top-level-categories"` → `"catalog/category/top-level"`
Line 67: `"catalog/category-browse-content-with-sidebar"` → `"catalog/category/content-with-sidebar"`
Line 69: `"catalog/category-browse"` → `"catalog/category/page"`
Line 82: `"catalog/category-children"` → `"catalog/category/children"`

**Step 4: Build to verify**

```bash
./gradlew build
```

Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add -A && git commit -m "refactor: move category templates to catalog/category/ directory"
```

---

### Task 3: Move product templates

**Files:**
- Move: `catalog/product-group.jte` → `catalog/product/page.jte`
- Move: `catalog/product-group-content.jte` → `catalog/product/content.jte`
- Move: `catalog/product-group-filtered.jte` → `catalog/product/filtered.jte`
- Move: `catalog/filter-panel.jte` → `catalog/product/filter-panel.jte`
- Move: `catalog/filter-facet.jte` → `catalog/product/filter-facet.jte`
- Move: `catalog/variant-table.jte` → `catalog/product/variant-table.jte`
- Modify: `src/main/java/com/storefront/catalog/product/ProductController.java`

All paths below are relative to `src/main/resources/templates/jte/`.

**Step 1: Move the 6 product templates**

```bash
TPL=src/main/resources/templates/jte
git mv $TPL/catalog/product-group.jte $TPL/catalog/product/page.jte
git mv $TPL/catalog/product-group-content.jte $TPL/catalog/product/content.jte
git mv $TPL/catalog/product-group-filtered.jte $TPL/catalog/product/filtered.jte
git mv $TPL/catalog/filter-panel.jte $TPL/catalog/product/filter-panel.jte
git mv $TPL/catalog/filter-facet.jte $TPL/catalog/product/filter-facet.jte
git mv $TPL/catalog/variant-table.jte $TPL/catalog/product/variant-table.jte
```

**Step 2: Update `@template.*` references in moved templates**

In `catalog/product/page.jte` (was `product-group.jte`):

Line 17: `@template.catalog.product-group-content(` → `@template.catalog.product.content(`

In `catalog/product/content.jte` (was `product-group-content.jte`):

Line 58: `@template.catalog.filter-panel(` → `@template.catalog.product.filter-panel(`
Line 69: `@template.catalog.variant-table(` → `@template.catalog.product.variant-table(`

In `catalog/product/filtered.jte` (was `product-group-filtered.jte`):

Line 17: `@template.catalog.variant-table(` → `@template.catalog.product.variant-table(`

In `catalog/product/filter-panel.jte` (was `filter-panel.jte`):

Line 12: `@template.catalog.filter-facet(` → `@template.catalog.product.filter-facet(`

**Step 3: Update ProductController product return strings**

In `src/main/java/com/storefront/catalog/product/ProductController.java`:

Line 111: `"catalog/product-group-content"` → `"catalog/product/content"`
Line 113: `"catalog/product-group"` → `"catalog/product/page"`
Line 142: `"catalog/product-group-filtered"` → `"catalog/product/filtered"`

**Step 4: Build to verify**

```bash
./gradlew build
```

Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add -A && git commit -m "refactor: move product templates to catalog/product/ directory"
```

---

### Task 4: Move search templates

**Files:**
- Move: `catalog/search-results.jte` → `catalog/search/page.jte`
- Move: `catalog/search-results-content.jte` → `catalog/search/content.jte`
- Move: `catalog/search-dropdown.jte` → `catalog/search/dropdown.jte`
- Move: `catalog/search-dropdown-empty.jte` → `catalog/search/dropdown-empty.jte`
- Modify: `src/main/java/com/storefront/catalog/product/ProductController.java`

All paths below are relative to `src/main/resources/templates/jte/`.

**Step 1: Move the 4 search templates**

```bash
TPL=src/main/resources/templates/jte
git mv $TPL/catalog/search-results.jte $TPL/catalog/search/page.jte
git mv $TPL/catalog/search-results-content.jte $TPL/catalog/search/content.jte
git mv $TPL/catalog/search-dropdown.jte $TPL/catalog/search/dropdown.jte
git mv $TPL/catalog/search-dropdown-empty.jte $TPL/catalog/search/dropdown-empty.jte
```

**Step 2: Update `@template.*` references in moved templates**

In `catalog/search/page.jte` (was `search-results.jte`):

Line 15: `@template.catalog.search-results-content(` → `@template.catalog.search.content(`

**Step 3: Update ProductController search return strings**

In `src/main/java/com/storefront/catalog/product/ProductController.java`:

Line 159: `"catalog/search-dropdown-empty"` → `"catalog/search/dropdown-empty"`
Line 168: `"catalog/search-dropdown"` → `"catalog/search/dropdown"`
Line 196: `"catalog/search-results-content"` → `"catalog/search/content"`
Line 198: `"catalog/search-results"` → `"catalog/search/page"`

**Step 4: Build to verify**

```bash
./gradlew build
```

Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add -A && git commit -m "refactor: move search templates to catalog/search/ directory"
```

---

### Task 5: Final verification and cleanup

**Step 1: Verify the old `catalog/` directory only contains subdirectories**

```bash
ls src/main/resources/templates/jte/catalog/
```

Expected output: `category/  product/  search/` (only subdirectories, no loose .jte files)

**Step 2: Verify no stale root templates remain**

```bash
ls src/main/resources/templates/jte/*.jte
```

Expected output: only `.jteroot` (no `index.jte`, `home-content*.jte`)

**Step 3: Full build + test**

```bash
./gradlew clean build
```

Expected: BUILD SUCCESSFUL

**Step 4: Verify final structure**

```bash
find src/main/resources/templates/jte -name "*.jte" | sort
```

Expected:
```
src/main/resources/templates/jte/catalog/category/children.jte
src/main/resources/templates/jte/catalog/category/content-with-sidebar.jte
src/main/resources/templates/jte/catalog/category/content.jte
src/main/resources/templates/jte/catalog/category/filter-sidebar.jte
src/main/resources/templates/jte/catalog/category/page.jte
src/main/resources/templates/jte/catalog/category/top-level.jte
src/main/resources/templates/jte/catalog/product/content.jte
src/main/resources/templates/jte/catalog/product/filter-facet.jte
src/main/resources/templates/jte/catalog/product/filter-panel.jte
src/main/resources/templates/jte/catalog/product/filtered.jte
src/main/resources/templates/jte/catalog/product/page.jte
src/main/resources/templates/jte/catalog/product/variant-table.jte
src/main/resources/templates/jte/catalog/search/content.jte
src/main/resources/templates/jte/catalog/search/dropdown-empty.jte
src/main/resources/templates/jte/catalog/search/dropdown.jte
src/main/resources/templates/jte/catalog/search/page.jte
src/main/resources/templates/jte/fragments/footer.jte
src/main/resources/templates/jte/fragments/nav.jte
src/main/resources/templates/jte/fragments/sidebar.jte
src/main/resources/templates/jte/home/content-with-sidebar.jte
src/main/resources/templates/jte/home/content.jte
src/main/resources/templates/jte/home/page.jte
src/main/resources/templates/jte/layouts/main.jte
```