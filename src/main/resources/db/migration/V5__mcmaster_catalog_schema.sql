-- ════════════════════════════════════════════════════════════════════════════
-- V5__mcmaster_catalog_schema.sql
-- McMaster-Carr style product schema: hierarchical categories (ltree),
-- product groups, SKUs with denormalized specs, EAV attributes for filtering,
-- quantity-break pricing, and product media.
-- ════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "ltree";

-- ── 1. CATEGORIES (ltree-based hierarchy) ───────────────────────────────────

CREATE TABLE categories (
    id              SERIAL PRIMARY KEY,
    parent_id       INT REFERENCES categories(id) ON DELETE RESTRICT,
    slug            VARCHAR(100) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    path            LTREE NOT NULL,
    depth           SMALLINT NOT NULL DEFAULT 0,
    is_leaf         BOOLEAN NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order      SMALLINT NOT NULL DEFAULT 0,
    group_count     INT NOT NULL DEFAULT 0,
    seo_title       VARCHAR(200),
    seo_description VARCHAR(400),

    CONSTRAINT uq_category_path        UNIQUE (path),
    CONSTRAINT uq_category_slug_parent UNIQUE (parent_id, slug)
);

CREATE INDEX idx_cat_path_gist  ON categories USING GIST (path);
CREATE INDEX idx_cat_path_btree ON categories (path);
CREATE INDEX idx_cat_parent     ON categories (parent_id);
CREATE INDEX idx_cat_active     ON categories (is_active, sort_order)
    WHERE is_active = TRUE;


-- ── 2. ATTRIBUTE DEFINITIONS ────────────────────────────────────────────────

CREATE TABLE attribute_definitions (
    id              SERIAL PRIMARY KEY,
    category_id     INT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    key             VARCHAR(80) NOT NULL,
    label           VARCHAR(120) NOT NULL,
    unit_label      VARCHAR(30),
    data_type       VARCHAR(10) NOT NULL DEFAULT 'enum'
                    CHECK (data_type IN ('enum','number','boolean','text')),
    filter_widget   VARCHAR(20) NOT NULL DEFAULT 'checkbox'
                    CHECK (filter_widget IN ('checkbox','range','toggle','none')),
    is_filterable   BOOLEAN NOT NULL DEFAULT TRUE,
    filter_sort_order SMALLINT NOT NULL DEFAULT 0,
    is_table_column   BOOLEAN NOT NULL DEFAULT TRUE,
    table_sort_order  SMALLINT NOT NULL DEFAULT 0,
    table_column_width SMALLINT NOT NULL DEFAULT 110,
    is_detail_spec  BOOLEAN NOT NULL DEFAULT FALSE,
    tooltip         TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_attr_key_category UNIQUE (category_id, key)
);

CREATE INDEX idx_attr_category    ON attribute_definitions (category_id);
CREATE INDEX idx_attr_filterable  ON attribute_definitions (category_id, is_filterable, filter_sort_order)
    WHERE is_filterable = TRUE;
CREATE INDEX idx_attr_table_col   ON attribute_definitions (category_id, is_table_column, table_sort_order)
    WHERE is_table_column = TRUE;


-- ── 3. ATTRIBUTE OPTIONS ────────────────────────────────────────────────────

CREATE TABLE attribute_options (
    id              SERIAL PRIMARY KEY,
    attribute_id    INT NOT NULL REFERENCES attribute_definitions(id) ON DELETE CASCADE,
    value           VARCHAR(150) NOT NULL,
    display_value   VARCHAR(200),
    sort_order      SMALLINT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_option_value UNIQUE (attribute_id, value)
);

CREATE INDEX idx_opt_attribute ON attribute_options (attribute_id, sort_order)
    WHERE is_active = TRUE;


-- ── 4. PRODUCT GROUPS ───────────────────────────────────────────────────────

CREATE TABLE product_groups (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id     INT NOT NULL REFERENCES categories(id),
    name            VARCHAR(300) NOT NULL,
    subtitle        VARCHAR(300),
    slug            VARCHAR(320) NOT NULL UNIQUE,
    description     TEXT,
    engineering_note TEXT,
    overview_image_url TEXT,
    diagram_image_url  TEXT,
    sku_count       INT NOT NULL DEFAULT 0,
    min_price_usd   NUMERIC(12,4),
    any_in_stock    BOOLEAN NOT NULL DEFAULT FALSE,
    default_sort_key  VARCHAR(80),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order      SMALLINT NOT NULL DEFAULT 0,
    search_vector   TSVECTOR,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pg_category      ON product_groups (category_id);
CREATE INDEX idx_pg_active        ON product_groups (is_active, sort_order) WHERE is_active;
CREATE INDEX idx_pg_search        ON product_groups USING GIN (search_vector);
CREATE INDEX idx_pg_name_trgm     ON product_groups USING GIN (name gin_trgm_ops);


-- ── 5. PRODUCT GROUP COLUMNS ────────────────────────────────────────────────

CREATE TABLE product_group_columns (
    id                  SERIAL PRIMARY KEY,
    product_group_id    UUID NOT NULL REFERENCES product_groups(id) ON DELETE CASCADE,
    attribute_id        INT  NOT NULL REFERENCES attribute_definitions(id),
    role                VARCHAR(20) NOT NULL DEFAULT 'column'
                        CHECK (role IN ('sort_primary','sort_secondary','column','filter_only')),
    column_header       VARCHAR(80),
    column_width_px     SMALLINT,
    sort_order          SMALLINT NOT NULL DEFAULT 0,

    CONSTRAINT uq_pg_col UNIQUE (product_group_id, attribute_id)
);

CREATE INDEX idx_pgcol_group ON product_group_columns (product_group_id, sort_order);


-- ── 6. SKUs ─────────────────────────────────────────────────────────────────

CREATE TABLE skus (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_group_id UUID NOT NULL REFERENCES product_groups(id) ON DELETE CASCADE,
    part_number     VARCHAR(80) NOT NULL UNIQUE,
    name            VARCHAR(500) NOT NULL,
    specs_jsonb     JSONB NOT NULL DEFAULT '{}',
    sort_key        VARCHAR(200) NOT NULL DEFAULT '',
    in_stock        BOOLEAN NOT NULL DEFAULT FALSE,
    price_1ea       NUMERIC(12,4),
    sell_unit       VARCHAR(60) NOT NULL DEFAULT 'Each',
    sell_qty        INT NOT NULL DEFAULT 1,
    weight_lbs      NUMERIC(10,4),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sku_group          ON skus (product_group_id, is_active, sort_key);
CREATE INDEX idx_sku_part_number    ON skus (part_number);
CREATE INDEX idx_sku_specs          ON skus USING GIN (specs_jsonb);
CREATE INDEX idx_sku_in_stock       ON skus (product_group_id, in_stock) WHERE in_stock = TRUE;
CREATE INDEX idx_sku_price          ON skus (product_group_id, price_1ea);


-- ── 7. SKU ATTRIBUTES (EAV — filter path only) ─────────────────────────────

CREATE TABLE sku_attributes (
    sku_id          UUID NOT NULL REFERENCES skus(id) ON DELETE CASCADE,
    attribute_id    INT  NOT NULL REFERENCES attribute_definitions(id),
    value_text      VARCHAR(200),
    value_numeric   NUMERIC(18,6),
    option_id       INT REFERENCES attribute_options(id),

    PRIMARY KEY (sku_id, attribute_id)
);

CREATE INDEX idx_sa_enum_filter   ON sku_attributes (attribute_id, option_id)
    WHERE option_id IS NOT NULL;
CREATE INDEX idx_sa_range_filter  ON sku_attributes (attribute_id, value_numeric)
    WHERE value_numeric IS NOT NULL;
CREATE INDEX idx_sa_text_filter   ON sku_attributes (attribute_id, value_text)
    WHERE value_text IS NOT NULL;
CREATE INDEX idx_sa_sku           ON sku_attributes (sku_id);


-- ── 8. SKU PRICE TIERS ─────────────────────────────────────────────────────

CREATE TABLE sku_price_tiers (
    id              SERIAL PRIMARY KEY,
    sku_id          UUID NOT NULL REFERENCES skus(id) ON DELETE CASCADE,
    qty_min         INT NOT NULL CHECK (qty_min >= 1),
    qty_max         INT CHECK (qty_max IS NULL OR qty_max >= qty_min),
    unit_price      NUMERIC(12,4) NOT NULL CHECK (unit_price >= 0),
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_price_tier UNIQUE (sku_id, currency, qty_min)
);

CREATE INDEX idx_price_sku ON sku_price_tiers (sku_id, currency, is_active);


-- ── 9. PRODUCT MEDIA ───────────────────────────────────────────────────────

CREATE TABLE product_media (
    id              SERIAL PRIMARY KEY,
    product_group_id UUID REFERENCES product_groups(id) ON DELETE CASCADE,
    sku_id          UUID REFERENCES skus(id) ON DELETE CASCADE,
    kind            VARCHAR(30) NOT NULL
                    CHECK (kind IN (
                        'image_overview','image_diagram','image_alt',
                        'cad_step','cad_dxf','cad_stl',
                        'pdf_datasheet','pdf_sds'
                    )),
    url             TEXT NOT NULL,
    alt_text        VARCHAR(300),
    sort_order      SMALLINT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_media_parent CHECK (
        product_group_id IS NOT NULL OR sku_id IS NOT NULL
    )
);

CREATE INDEX idx_media_group ON product_media (product_group_id, kind, sort_order)
    WHERE product_group_id IS NOT NULL AND is_active = TRUE;
CREATE INDEX idx_media_sku   ON product_media (sku_id, kind, sort_order)
    WHERE sku_id IS NOT NULL AND is_active = TRUE;


-- ════════════════════════════════════════════════════════════════════════════
-- TRIGGERS & FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- ── updated_at ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := NOW(); RETURN NEW; END; $$;

CREATE TRIGGER trg_pg_updated_at
    BEFORE UPDATE ON product_groups
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_sku_updated_at
    BEFORE UPDATE ON skus
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ── Product group search vector ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_pg_search_vector()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.search_vector :=
        SETWEIGHT(TO_TSVECTOR('english', COALESCE(NEW.name, '')),         'A') ||
        SETWEIGHT(TO_TSVECTOR('english', COALESCE(NEW.subtitle, '')),     'B') ||
        SETWEIGHT(TO_TSVECTOR('english', COALESCE(NEW.description, '')),  'C');
    RETURN NEW;
END; $$;

CREATE TRIGGER trg_pg_search_vector
    BEFORE INSERT OR UPDATE OF name, subtitle, description
    ON product_groups
    FOR EACH ROW EXECUTE FUNCTION fn_pg_search_vector();


-- ── SKU specs_jsonb + sort_key rebuild ──────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_rebuild_sku_snapshot()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_sku_id UUID;
    v_specs  JSONB;
    v_sort   TEXT;
BEGIN
    v_sku_id := COALESCE(NEW.sku_id, OLD.sku_id);

    SELECT
        jsonb_object_agg(
            ad.key,
            COALESCE(ao.display_value, ao.value, sa.value_text,
                     sa.value_numeric::TEXT)
        ),
        STRING_AGG(
            LPAD(COALESCE(ao.sort_order, 0)::TEXT, 6, '0'),
            '_' ORDER BY ad.table_sort_order
        )
    INTO v_specs, v_sort
    FROM sku_attributes sa
    JOIN attribute_definitions ad ON ad.id = sa.attribute_id
    LEFT JOIN attribute_options ao ON ao.id = sa.option_id
    WHERE sa.sku_id = v_sku_id
      AND ad.is_active = TRUE;

    UPDATE skus
    SET specs_jsonb = COALESCE(v_specs, '{}'),
        sort_key    = COALESCE(v_sort, '')
    WHERE id = v_sku_id;

    RETURN NULL;
END; $$;

CREATE TRIGGER trg_rebuild_sku_snapshot
    AFTER INSERT OR UPDATE OR DELETE ON sku_attributes
    FOR EACH ROW EXECUTE FUNCTION fn_rebuild_sku_snapshot();


-- ── SKU price_1ea denorm ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_update_price_1ea()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE skus
    SET price_1ea = (
        SELECT unit_price FROM sku_price_tiers
        WHERE sku_id = COALESCE(NEW.sku_id, OLD.sku_id)
          AND currency = 'USD'
          AND qty_min = 1
          AND is_active = TRUE
        LIMIT 1
    )
    WHERE id = COALESCE(NEW.sku_id, OLD.sku_id);
    RETURN NULL;
END; $$;

CREATE TRIGGER trg_update_price_1ea
    AFTER INSERT OR UPDATE OR DELETE ON sku_price_tiers
    FOR EACH ROW EXECUTE FUNCTION fn_update_price_1ea();


-- ── Product group denorm counters ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_update_pg_denorm()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_gid UUID;
BEGIN
    v_gid := COALESCE(NEW.product_group_id, OLD.product_group_id);
    UPDATE product_groups
    SET
        sku_count     = (SELECT COUNT(*) FROM skus WHERE product_group_id = v_gid AND is_active),
        min_price_usd = (
            SELECT MIN(pt.unit_price)
            FROM skus s
            JOIN sku_price_tiers pt ON pt.sku_id = s.id
            WHERE s.product_group_id = v_gid
              AND s.is_active AND pt.qty_min = 1 AND pt.is_active AND pt.currency = 'USD'
        ),
        any_in_stock  = EXISTS (
            SELECT 1 FROM skus WHERE product_group_id = v_gid AND is_active AND in_stock
        )
    WHERE id = v_gid;
    RETURN NULL;
END; $$;

CREATE TRIGGER trg_pg_denorm_on_sku
    AFTER INSERT OR UPDATE OR DELETE ON skus
    FOR EACH ROW EXECUTE FUNCTION fn_update_pg_denorm();


-- ── Category group_count ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_update_category_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE categories c
    SET group_count = (
        SELECT COUNT(*) FROM product_groups pg
        JOIN categories lc ON lc.id = pg.category_id
        WHERE lc.path <@ c.path AND pg.is_active
    )
    WHERE c.path @> (
        SELECT path FROM categories WHERE id =
            NEW.category_id
    );
    RETURN NULL;
END; $$;

CREATE TRIGGER trg_cat_count
    AFTER INSERT OR UPDATE OF is_active OR DELETE ON product_groups
    FOR EACH ROW EXECUTE FUNCTION fn_update_category_count();
