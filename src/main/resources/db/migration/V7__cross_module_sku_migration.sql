-- ════════════════════════════════════════════════════════════════════════════
-- V7__cross_module_sku_migration.sql
-- Migrate inventory, reorder_rule, and cart_item tables from product_id to sku_id.
-- ════════════════════════════════════════════════════════════════════════════

-- ── Inventory: product_id → sku_id ────────────────────────────────────────

ALTER TABLE inventory DROP CONSTRAINT IF EXISTS inventory_product_id_fkey;
ALTER TABLE inventory DROP CONSTRAINT IF EXISTS uq_inventory_product;
DROP INDEX IF EXISTS idx_inventory_product_id;
DROP INDEX IF EXISTS idx_inventory_in_stock;

ALTER TABLE inventory RENAME COLUMN product_id TO sku_id;

ALTER TABLE inventory ADD CONSTRAINT uq_inventory_sku UNIQUE (sku_id);
CREATE INDEX idx_inventory_sku_id ON inventory(sku_id);
CREATE INDEX idx_inventory_in_stock ON inventory(sku_id, quantity) WHERE quantity > 0;

-- ── Reorder rule: product_id → sku_id ─────────────────────────────────────

ALTER TABLE reorder_rule DROP CONSTRAINT IF EXISTS reorder_rule_product_id_fkey;
ALTER TABLE reorder_rule DROP CONSTRAINT IF EXISTS uq_reorder_rule_product;
DROP INDEX IF EXISTS idx_reorder_rule_product;

ALTER TABLE reorder_rule RENAME COLUMN product_id TO sku_id;

ALTER TABLE reorder_rule ADD CONSTRAINT uq_reorder_rule_sku UNIQUE (sku_id);
CREATE INDEX idx_reorder_rule_sku ON reorder_rule(sku_id);

-- ── Cart item: product_id → sku_id ────────────────────────────────────────

ALTER TABLE cart_item DROP CONSTRAINT IF EXISTS cart_item_product_id_fkey;
ALTER TABLE cart_item DROP CONSTRAINT IF EXISTS uq_cart_item_product;
DROP INDEX IF EXISTS idx_cart_item_product_id;

ALTER TABLE cart_item RENAME COLUMN product_id TO sku_id;

ALTER TABLE cart_item ADD CONSTRAINT uq_cart_item_sku UNIQUE (cart_id, sku_id);
CREATE INDEX idx_cart_item_sku_id ON cart_item(sku_id);
