---
name: storefront-schema
description: Use when creating or modifying database schema — Flyway migrations, jOOQ code generation, and record-to-domain mappers. Enforces naming conventions, column standards, and indexing patterns.
argument-hint: "[module-name or description]"
---

# Schema — Flyway + jOOQ + Mapping

Handles database schema changes for the storefront project.

## Flyway Migration Conventions

**File naming:** `V{next_number}__{snake_case_description}.sql`
- Find the current highest version: `ls src/main/resources/db/migration/`
- Increment by 1
- Double underscore between version and description
- Example: `V11__create_orders_tables.sql`

**Location:** `src/main/resources/db/migration/`

## Table Conventions

```sql
-- Table names: snake_case, plural
CREATE TABLE orders (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- business columns here
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Required columns on every table:**
- `id` — UUID primary key with default
- `created_at` — TIMESTAMPTZ NOT NULL DEFAULT NOW()
- `updated_at` — TIMESTAMPTZ NOT NULL DEFAULT NOW()

**Naming rules:**
- Tables: snake_case, plural (`orders`, `order_items`, `shipping_addresses`)
- Columns: snake_case (`order_status`, `total_amount_usd`)
- Foreign keys: `<singular_table>_id` (e.g., `order_id`, `category_id`)
- Indexes: `idx_<table>_<columns>` (e.g., `idx_orders_customer_id`)
- Constraints: `chk_<table>_<description>` (e.g., `chk_orders_positive_total`)

**Data types:**
- IDs: `UUID`
- Money: `NUMERIC(12, 2)` — never use FLOAT/DOUBLE for money
- Text: `TEXT` (not VARCHAR unless there's a hard DB-level limit)
- Booleans: `BOOLEAN NOT NULL DEFAULT FALSE`
- Flexible attributes: `JSONB`
- Full-text search: add `tsvector` column + GIN index
- Hierarchical paths: `ltree` (already enabled in this project)

**Cross-module foreign keys:**
- Allowed at DB level for referential integrity
- But domain model MUST reference by ID value object, not join

## Indexing Patterns

```sql
-- Foreign key index (always)
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- Full-text search
ALTER TABLE orders ADD COLUMN search_vector TSVECTOR;
CREATE INDEX idx_orders_search ON orders USING GIN(search_vector);

-- Trigram for fuzzy search (extension already enabled)
CREATE INDEX idx_orders_name_trgm ON orders USING GIN(name gin_trgm_ops);

-- JSONB for attribute queries
CREATE INDEX idx_skus_attributes ON skus USING GIN(attributes jsonb_path_ops);
```

## After Writing Migration

**Always regenerate jOOQ classes:**

```bash
./gradlew generateJooqClasses
```

This uses Testcontainers to spin up a PostgreSQL instance, apply all migrations, and generate classes to `src/generated/java/com/storefront/jooq/`.

**Verify generation succeeded:**
```bash
ls src/generated/java/com/storefront/jooq/tables/
```

New tables should appear as generated Java classes.

## jOOQ Mapper Pattern

After jOOQ classes are generated, write a mapper method in the infrastructure repository:

```java
// Pattern: private method in the jOOQ repository class
private DomainEntity toDomain(Record r) {
    return new DomainEntity(
        new EntityId(r.get(TABLE.ID)),
        r.get(TABLE.NAME),
        // ... map all columns to domain types
        r.get(TABLE.CREATED_AT).toInstant()
    );
}
```

**Rules:**
- Mapper is a private method on the repository implementation
- Converts jOOQ `Record` → domain entity
- Wraps raw IDs in value objects
- Converts `OffsetDateTime` → `Instant` when needed
- Never returns jOOQ records to callers
