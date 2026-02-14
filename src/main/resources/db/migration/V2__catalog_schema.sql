-- ════════════════════════════════════════════════════════════════════════════
-- V2__catalog_schema.sql
-- Catalog module: products, categories, full-text search
-- ════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ─── Categories ───────────────────────────────────────────────────────────────

CREATE TABLE category (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id     UUID REFERENCES category(id) ON DELETE RESTRICT,
    slug          TEXT NOT NULL UNIQUE,
    name          TEXT NOT NULL,
    description   TEXT,
    display_order INT  NOT NULL DEFAULT 0,
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_category_parent ON category(parent_id);
CREATE INDEX idx_category_slug   ON category(slug);
CREATE INDEX idx_category_active ON category(active) WHERE active = TRUE;

-- ─── Products ─────────────────────────────────────────────────────────────────

CREATE TABLE product (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku             TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    description     TEXT,
    category_id     UUID NOT NULL REFERENCES category(id),
    price           NUMERIC(12, 2) NOT NULL,
    unit_of_measure TEXT NOT NULL DEFAULT 'each',
    thumbnail_key   TEXT,
    image_keys      TEXT[],
    attributes      JSONB,                         -- product specs: {"thread_size":"M6","length_mm":20}
    display_order   INT NOT NULL DEFAULT 0,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    search_vector   TSVECTOR                       -- maintained by trigger below
);

-- Standard indexes
CREATE INDEX idx_product_category      ON product(category_id);
CREATE INDEX idx_product_sku           ON product(sku);
CREATE INDEX idx_product_active        ON product(active) WHERE active = TRUE;
CREATE INDEX idx_product_price         ON product(price);
CREATE INDEX idx_product_display_order ON product(category_id, display_order);

-- GIN indexes for search
CREATE INDEX idx_product_search_vector ON product USING GIN (search_vector);
CREATE INDEX idx_product_attributes    ON product USING GIN (attributes);
CREATE INDEX idx_product_name_trgm     ON product USING GIN (name gin_trgm_ops);

-- ─── Full-text search trigger ─────────────────────────────────────────────────

CREATE FUNCTION product_search_vector_update() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', coalesce(NEW.sku, '')),         'A') ||
        setweight(to_tsvector('english', coalesce(NEW.name, '')),        'B') ||
        setweight(to_tsvector('english', coalesce(NEW.description, '')), 'C');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_search_vector
    BEFORE INSERT OR UPDATE OF sku, name, description
    ON product
    FOR EACH ROW EXECUTE FUNCTION product_search_vector_update();

-- ─── Materialized view: category product counts ───────────────────────────────
-- Avoids live COUNT(*) on every category page load.
-- Refresh via: REFRESH MATERIALIZED VIEW CONCURRENTLY category_product_counts;

CREATE MATERIALIZED VIEW category_product_counts AS
    SELECT
        p.category_id,
        COUNT(*)                                 AS total_products,
        MIN(p.price)                             AS min_price,
        MAX(p.price)                             AS max_price
    FROM product p
    WHERE p.active = TRUE
    GROUP BY p.category_id
WITH DATA;

CREATE UNIQUE INDEX ON category_product_counts(category_id);

-- ─── Timestamps trigger ───────────────────────────────────────────────────────

CREATE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_updated_at BEFORE UPDATE ON category FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_product_updated_at  BEFORE UPDATE ON product  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
