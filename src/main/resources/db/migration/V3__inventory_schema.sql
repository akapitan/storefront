-- ════════════════════════════════════════════════════════════════════════════
-- V3__inventory_schema.sql
-- Inventory module: stock levels, warehouse locations, reorder rules
-- Depends on: V2__catalog_schema.sql (product table)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── Inventory (stock levels) ─────────────────────────────────────────────────

CREATE TABLE inventory (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id         UUID NOT NULL REFERENCES product(id) ON DELETE RESTRICT,
    warehouse_location TEXT,                           -- e.g. "B3-12-4"
    quantity           INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reorder_point      INT NOT NULL DEFAULT 10,        -- publish InventoryLow when qty <= this
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_inventory_product UNIQUE (product_id)
);

CREATE INDEX idx_inventory_product_id ON inventory(product_id);

-- Partial index: only in-stock items (most queries filter for quantity > 0)
CREATE INDEX idx_inventory_in_stock ON inventory(product_id, quantity)
    WHERE quantity > 0;

-- ─── Warehouse locations ──────────────────────────────────────────────────────

CREATE TABLE warehouse_location (
    id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code     TEXT NOT NULL UNIQUE,                     -- e.g. "B3-12-4"
    aisle    TEXT NOT NULL,
    bay      TEXT NOT NULL,
    level    TEXT NOT NULL,
    active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_warehouse_location_code ON warehouse_location(code);

-- ─── Reorder rules ────────────────────────────────────────────────────────────

CREATE TABLE reorder_rule (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id          UUID NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    reorder_quantity    INT NOT NULL DEFAULT 100 CHECK (reorder_quantity > 0),
    supplier_lead_days  INT NOT NULL DEFAULT 7,
    auto_reorder        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_reorder_rule_product UNIQUE (product_id)
);

CREATE INDEX idx_reorder_rule_product ON reorder_rule(product_id);

-- ─── Timestamps trigger (reuses function from V2) ─────────────────────────────

CREATE TRIGGER trg_inventory_updated_at
    BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
