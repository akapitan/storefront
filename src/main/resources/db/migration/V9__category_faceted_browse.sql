-- ── 1. Expand filter_widget CHECK constraint ─────────────────────────────────

DO $$
DECLARE v_conname TEXT;
BEGIN
    SELECT c.conname INTO v_conname
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE t.relname = 'attribute_definitions'
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) LIKE '%filter_widget%';
    IF v_conname IS NOT NULL THEN
        EXECUTE 'ALTER TABLE attribute_definitions DROP CONSTRAINT ' || quote_ident(v_conname);
    END IF;
END; $$;

ALTER TABLE attribute_definitions
    ADD CONSTRAINT chk_filter_widget
    CHECK (filter_widget IN ('checkbox','range','toggle','none','dropdown','image_grid','image_list'));


-- ── 2. Add image_url to attribute_options ────────────────────────────────────

ALTER TABLE attribute_options ADD COLUMN IF NOT EXISTS image_url TEXT;


-- ── 3. Create sku_facet_index ────────────────────────────────────────────────

CREATE TABLE sku_facet_index (
    sku_id           UUID    NOT NULL REFERENCES skus(id) ON DELETE CASCADE,
    category_id      INT     NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    attribute_id     INT     NOT NULL REFERENCES attribute_definitions(id) ON DELETE CASCADE,
    option_id        INT     REFERENCES attribute_options(id) ON DELETE CASCADE,
    value_numeric    NUMERIC(18,6),
    product_group_id UUID    NOT NULL REFERENCES product_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (sku_id, attribute_id)
);

CREATE INDEX idx_sfi_cat_attr_opt ON sku_facet_index (category_id, attribute_id, option_id);
CREATE INDEX idx_sfi_cat_attr_num ON sku_facet_index (category_id, attribute_id, value_numeric);
CREATE INDEX idx_sfi_group        ON sku_facet_index (product_group_id, attribute_id, option_id);
CREATE INDEX idx_sfi_sku          ON sku_facet_index (sku_id);


-- ── 4. Trigger to maintain sku_facet_index on sku_attributes changes ─────────

CREATE OR REPLACE FUNCTION fn_rebuild_sku_facet_index()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_sku_id UUID;
    v_cat_id INT;
    v_grp_id UUID;
BEGIN
    v_sku_id := COALESCE(NEW.sku_id, OLD.sku_id);

    SELECT s.product_group_id, c.id
    INTO v_grp_id, v_cat_id
    FROM skus s
    JOIN product_groups pg ON pg.id = s.product_group_id
    JOIN categories c ON c.id = pg.category_id
    WHERE s.id = v_sku_id;

    -- Remove the row for this (sku, attribute) pair
    DELETE FROM sku_facet_index
    WHERE sku_id = v_sku_id
      AND attribute_id = COALESCE(NEW.attribute_id, OLD.attribute_id);

    -- Re-insert for INSERT or UPDATE
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        INSERT INTO sku_facet_index
            (sku_id, category_id, attribute_id, option_id, value_numeric, product_group_id)
        VALUES
            (v_sku_id, v_cat_id, NEW.attribute_id, NEW.option_id, NEW.value_numeric, v_grp_id)
        ON CONFLICT (sku_id, attribute_id) DO UPDATE
            SET category_id      = EXCLUDED.category_id,
                option_id        = EXCLUDED.option_id,
                value_numeric    = EXCLUDED.value_numeric,
                product_group_id = EXCLUDED.product_group_id;
    END IF;

    RETURN NULL;
END; $$;

CREATE TRIGGER trg_rebuild_sku_facet_index
    AFTER INSERT OR UPDATE OR DELETE ON sku_attributes
    FOR EACH ROW EXECUTE FUNCTION fn_rebuild_sku_facet_index();


-- ── 5. Backfill existing data ────────────────────────────────────────────────

INSERT INTO sku_facet_index
    (sku_id, category_id, attribute_id, option_id, value_numeric, product_group_id)
SELECT
    sa.sku_id,
    c.id  AS category_id,
    sa.attribute_id,
    sa.option_id,
    sa.value_numeric,
    pg.id AS product_group_id
FROM sku_attributes sa
JOIN skus s        ON s.id  = sa.sku_id
JOIN product_groups pg ON pg.id = s.product_group_id
JOIN categories c  ON c.id  = pg.category_id
ON CONFLICT (sku_id, attribute_id) DO NOTHING;