-- ════════════════════════════════════════════════════════════════════════════
-- V4__cart_schema.sql
-- Cart module: shopping cart and cart items
-- Depends on: V2__catalog_schema.sql (product table)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── Shopping Cart ────────────────────────────────────────────────────────────

CREATE TABLE cart (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id     UUID,                               -- NULL for anonymous/guest carts
    session_id      TEXT NOT NULL,                      -- HTTP session ID
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ,                        -- Auto-cleanup after 30 days for anonymous

    CONSTRAINT uq_cart_session UNIQUE (session_id)
);

CREATE INDEX idx_cart_customer   ON cart(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_cart_session    ON cart(session_id);
CREATE INDEX idx_cart_expires_at ON cart(expires_at) WHERE expires_at IS NOT NULL;

COMMENT ON TABLE cart IS 'Shopping carts — session-based for anonymous users, customer-linked for authenticated users';
COMMENT ON COLUMN cart.customer_id IS 'Links to customer when authenticated (future: FK to customer table)';
COMMENT ON COLUMN cart.session_id IS 'HTTP session ID — ensures cart persistence across page loads';
COMMENT ON COLUMN cart.expires_at IS 'Expiration timestamp for anonymous carts (30 days); NULL for customer carts';

-- ─── Cart Items ───────────────────────────────────────────────────────────────

CREATE TABLE cart_item (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id         UUID NOT NULL REFERENCES cart(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES product(id),
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12, 2) NOT NULL,            -- Price snapshot at add time
    added_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_cart_item_product UNIQUE (cart_id, product_id)
);

CREATE INDEX idx_cart_item_cart_id    ON cart_item(cart_id);
CREATE INDEX idx_cart_item_product_id ON cart_item(product_id);

COMMENT ON TABLE cart_item IS 'Line items within a shopping cart';
COMMENT ON COLUMN cart_item.unit_price IS 'Price snapshot when item added — prevents retroactive price changes';
COMMENT ON CONSTRAINT uq_cart_item_product ON cart_item IS 'Prevent duplicate products in same cart (merge quantities instead)';

-- ─── Cart cleanup function ────────────────────────────────────────────────────
-- Scheduled job can call: SELECT cleanup_expired_carts();

CREATE FUNCTION cleanup_expired_carts() RETURNS INT AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM cart WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_expired_carts IS 'Deletes expired anonymous carts — run via scheduled job';

