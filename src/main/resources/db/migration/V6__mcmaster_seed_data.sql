-- ════════════════════════════════════════════════════════════════════════════
-- V6__mcmaster_seed_data.sql
-- Sample data for the McMaster-Carr style catalog schema.
-- ════════════════════════════════════════════════════════════════════════════

-- ── Categories ──────────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order) VALUES
(NULL, 'fastening',     'Fastening & Sealing',  'Fastening',            0, FALSE, 1),
(NULL, 'raw-materials', 'Raw Materials',         'RawMaterials',         0, FALSE, 2),
(NULL, 'electrical',    'Electrical',            'Electrical',           0, FALSE, 3),
(NULL, 'hand-tools',    'Hand Tools',            'HandTools',            0, FALSE, 4);

-- Level 1 under Fastening
INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('bolts',   'Bolts',   'Bolts',   1),
    ('nuts',    'Nuts',    'Nuts',    2),
    ('washers', 'Washers', 'Washers', 3),
    ('screws',  'Screws',  'Screws',  4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'fastening';

-- Level 2 under Bolts (leaf nodes)
INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hex-head-cap-screws',    'Hex Head Cap Screws',    'HexHeadCapScrews',    1),
    ('socket-head-cap-screws', 'Socket Head Cap Screws', 'SocketHeadCapScrews', 2),
    ('carriage-bolts',         'Carriage Bolts',         'CarriageBolts',       3),
    ('shoulder-screws',        'Shoulder Screws',        'ShoulderScrews',      4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'bolts';


-- ── Attribute definitions ───────────────────────────────────────────────────

-- Material — defined on "Fastening" top-level, inherited by all sub-categories
INSERT INTO attribute_definitions
    (category_id, key, label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('material', 'Material', 'enum', 'checkbox', TRUE, 1, TRUE, 10, 120, 'Base material and alloy grade')
) AS v(key, label, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'fastening';

-- Material options
WITH attr AS (SELECT id FROM attribute_definitions WHERE key = 'material'
              AND category_id = (SELECT id FROM categories WHERE slug = 'fastening'))
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('zinc-steel',   'Zinc-Plated Steel',    1),
    ('18-8-ss',      '18-8 Stainless Steel', 2),
    ('316-ss',       '316 Stainless Steel',  3),
    ('plain-steel',  'Plain Steel',          4),
    ('brass',        'Brass',                5),
    ('nylon',        'Nylon',                6),
    ('alloy-steel',  'Alloy Steel',          7)
) AS v(val, dv, so);

-- Leaf-level attributes for Hex Head Cap Screws
INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('thread_size',  'Thread Size',          NULL,    'enum',   'checkbox',  TRUE, 2,  TRUE, 1,  130, 'Nominal diameter x pitch'),
    ('length_in',    'Length',               'in.',   'number', 'range',     TRUE, 3,  TRUE, 2,  100, 'Measured from underside of head to tip'),
    ('drive_type',   'Drive Type',           NULL,    'enum',   'checkbox',  TRUE, 4,  TRUE, 3,  100, 'Tool required to install'),
    ('head_type',    'Head Type',            NULL,    'enum',   'checkbox',  TRUE, 5,  FALSE, 4, 110, NULL),
    ('grade',        'Grade',                NULL,    'enum',   'checkbox',  TRUE, 6,  TRUE, 4,  110, 'Strength grade'),
    ('thread_type',  'Thread Type',          NULL,    'enum',   'checkbox',  TRUE, 7,  TRUE, 5,  100, 'Coarse (UNC) or Fine (UNF)'),
    ('pkg_qty',      'Package Qty',          'pc.',   'number', 'none',      FALSE,99, TRUE, 6,  80,  NULL),
    ('tensile_psi',  'Tensile Strength',     'psi',   'number', 'range',     TRUE, 8,  FALSE,99, 100, 'Minimum tensile strength')
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'hex-head-cap-screws';

-- Enum options for thread_size
WITH attr AS (SELECT ad.id FROM attribute_definitions ad
              JOIN categories c ON c.id = ad.category_id
              WHERE ad.key = 'thread_size' AND c.slug = 'hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('#4-40',   '#4-40',     1), ('#6-32',   '#6-32',     2), ('#8-32',  '#8-32',     3),
    ('#10-24',  '#10-24',    4), ('#10-32',  '#10-32',    5),
    ('1/4-20',  '1/4"-20',   6), ('1/4-28',  '1/4"-28',   7),
    ('5/16-18', '5/16"-18',  8), ('5/16-24', '5/16"-24',  9),
    ('3/8-16',  '3/8"-16',  10), ('3/8-24',  '3/8"-24',  11),
    ('7/16-14', '7/16"-14', 12), ('1/2-13',  '1/2"-13',  13),
    ('1/2-20',  '1/2"-20',  14), ('5/8-11',  '5/8"-11',  15),
    ('3/4-10',  '3/4"-10',  16), ('M4x0.7',  'M4 x 0.7', 17),
    ('M5x0.8',  'M5 x 0.8', 18), ('M6x1.0',  'M6 x 1.0', 19),
    ('M8x1.25', 'M8 x 1.25',20), ('M10x1.5', 'M10 x 1.5',21)
) AS v(val, dv, so);

-- Enum options for drive_type
WITH attr AS (SELECT ad.id FROM attribute_definitions ad
              JOIN categories c ON c.id = ad.category_id
              WHERE ad.key = 'drive_type' AND c.slug = 'hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('hex',      'Hex (Wrench)',   1),
    ('socket',   'Hex Socket',     2),
    ('torx',     'Torx',           3),
    ('slotted',  'Slotted',        4)
) AS v(val, dv, so);

-- Enum options for grade
WITH attr AS (SELECT ad.id FROM attribute_definitions ad
              JOIN categories c ON c.id = ad.category_id
              WHERE ad.key = 'grade' AND c.slug = 'hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('grade-2',   'Grade 2',            1),
    ('grade-5',   'Grade 5',            2),
    ('grade-8',   'Grade 8',            3),
    ('class-8-8', 'Class 8.8 (Metric)', 4),
    ('class-10-9','Class 10.9 (Metric)',5)
) AS v(val, dv, so);

-- Enum options for thread_type
WITH attr AS (SELECT ad.id FROM attribute_definitions ad
              JOIN categories c ON c.id = ad.category_id
              WHERE ad.key = 'thread_type' AND c.slug = 'hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('UNC',    'Coarse (UNC)', 1),
    ('UNF',    'Fine (UNF)',   2),
    ('metric', 'Metric',       3)
) AS v(val, dv, so);


-- ── Product Group ───────────────────────────────────────────────────────────

INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, engineering_note,
     overview_image_url, diagram_image_url, default_sort_key)
SELECT c.id,
    'Hex Head Cap Screws',
    'Zinc-Plated Steel',
    'hex-head-cap-screws-zinc-plated-steel',
    'General-purpose hex head cap screws machined to 2A thread tolerance. '
    'Zinc plating (ASTM B633 SC1, ~5 um) provides mild rust protection in dry indoor environments. '
    'Full threads from tip to underside of head. Compatible with standard 2B hex nuts.',
    'Tightening torque (dry): 1/4"-20 -> 8 ft-lb, 3/8"-16 -> 31 ft-lb, 1/2"-13 -> 75 ft-lb. '
    'For outdoor or high-humidity use, choose 18-8 or 316 stainless instead.',
    '/img/products/hex-cap-screw-zinc.jpg',
    '/img/diagrams/hex-cap-screw-dims.png',
    'thread_size'
FROM categories c WHERE c.slug = 'hex-head-cap-screws';


-- ── Column config for the variant table ─────────────────────────────────────

WITH pg AS (SELECT id FROM product_groups WHERE slug = 'hex-head-cap-screws-zinc-plated-steel')
INSERT INTO product_group_columns
    (product_group_id, attribute_id, role, sort_order)
SELECT pg.id, ad.id,
    CASE ad.key
        WHEN 'thread_size' THEN 'sort_primary'
        WHEN 'length_in'   THEN 'sort_secondary'
        ELSE 'column'
    END,
    ad.table_sort_order
FROM pg
JOIN attribute_definitions ad
    ON ad.category_id IN (
        SELECT c.id FROM categories c
        WHERE c.path @> (SELECT path FROM categories WHERE slug='hex-head-cap-screws')
    )
WHERE ad.is_active = TRUE
  AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE);


-- ── Sample SKUs ─────────────────────────────────────────────────────────────

WITH pg AS (SELECT id FROM product_groups WHERE slug = 'hex-head-cap-screws-zinc-plated-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt
FROM pg, (VALUES
    ('92240A105','1/4"-20 x 1/2" Hex Cap Screw, Zinc-Plated Steel',   0.0021),
    ('92240A106','1/4"-20 x 3/4" Hex Cap Screw, Zinc-Plated Steel',   0.0029),
    ('92240A107','1/4"-20 x 1"   Hex Cap Screw, Zinc-Plated Steel',   0.0037),
    ('92240A108','1/4"-20 x 1-1/2" Hex Cap Screw, Zinc-Plated Steel', 0.0054),
    ('92240A109','1/4"-20 x 2"   Hex Cap Screw, Zinc-Plated Steel',   0.0072),
    ('92240A121','3/8"-16 x 3/4" Hex Cap Screw, Zinc-Plated Steel',   0.0082),
    ('92240A122','3/8"-16 x 1"   Hex Cap Screw, Zinc-Plated Steel',   0.0101),
    ('92240A123','3/8"-16 x 1-1/2" Hex Cap Screw, Zinc-Plated Steel', 0.0140),
    ('92240A124','3/8"-16 x 2"   Hex Cap Screw, Zinc-Plated Steel',   0.0180),
    ('92240A150','1/2"-13 x 1"   Hex Cap Screw, Zinc-Plated Steel',   0.0197),
    ('92240A151','1/2"-13 x 1-1/2" Hex Cap Screw, Zinc-Plated Steel', 0.0271),
    ('92240A152','1/2"-13 x 2"   Hex Cap Screw, Zinc-Plated Steel',   0.0344),
    ('92240A153','1/2"-13 x 3"   Hex Cap Screw, Zinc-Plated Steel',   0.0496),
    ('92240A200','3/4"-10 x 2"   Hex Cap Screw, Zinc-Plated Steel',   0.0900)
) AS s(pn, nm, wt);


-- ── SKU Attribute values ────────────────────────────────────────────────────

DO $$
DECLARE
    v_sku         RECORD;
    v_attr_ts     INT;
    v_attr_len    INT;
    v_attr_mat    INT;
    v_attr_grade  INT;
    v_attr_ttype  INT;
    v_attr_drive  INT;
    v_opt_zinc    INT;
    v_opt_grade5  INT;
    v_opt_unc     INT;
    v_opt_hex     INT;
BEGIN
    SELECT ad.id INTO v_attr_ts    FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id WHERE ad.key='thread_size' AND c.slug='hex-head-cap-screws';
    SELECT ad.id INTO v_attr_len   FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id WHERE ad.key='length_in'   AND c.slug='hex-head-cap-screws';
    SELECT ad.id INTO v_attr_mat   FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id WHERE ad.key='material'    AND c.slug='fastening';
    SELECT ad.id INTO v_attr_grade FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id WHERE ad.key='grade'       AND c.slug='hex-head-cap-screws';
    SELECT ad.id INTO v_attr_ttype FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id WHERE ad.key='thread_type' AND c.slug='hex-head-cap-screws';
    SELECT ad.id INTO v_attr_drive FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id WHERE ad.key='drive_type'  AND c.slug='hex-head-cap-screws';
    SELECT ao.id INTO v_opt_zinc   FROM attribute_options ao WHERE ao.attribute_id=v_attr_mat   AND ao.value='zinc-steel';
    SELECT ao.id INTO v_opt_grade5 FROM attribute_options ao WHERE ao.attribute_id=v_attr_grade AND ao.value='grade-5';
    SELECT ao.id INTO v_opt_unc    FROM attribute_options ao WHERE ao.attribute_id=v_attr_ttype AND ao.value='UNC';
    SELECT ao.id INTO v_opt_hex    FROM attribute_options ao WHERE ao.attribute_id=v_attr_drive AND ao.value='hex';

    FOR v_sku IN (
        SELECT s.id, s.part_number
        FROM skus s WHERE s.part_number LIKE '92240A%'
    ) LOOP
        -- Thread size attribute
        INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
        SELECT v_sku.id, v_attr_ts, ao.value, ao.id
        FROM attribute_options ao
        WHERE ao.attribute_id = v_attr_ts
          AND (
              v_sku.part_number IN ('92240A105','92240A106','92240A107','92240A108','92240A109') AND ao.value = '1/4-20'
              OR v_sku.part_number IN ('92240A121','92240A122','92240A123','92240A124')           AND ao.value = '3/8-16'
              OR v_sku.part_number IN ('92240A150','92240A151','92240A152','92240A153')           AND ao.value = '1/2-13'
              OR v_sku.part_number = '92240A200'                                                  AND ao.value = '3/4-10'
          )
        ON CONFLICT DO NOTHING;

        -- Length attribute (numeric range filter)
        INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
        VALUES (v_sku.id, v_attr_len,
            CASE v_sku.part_number
                WHEN '92240A105' THEN '0.50'  WHEN '92240A106' THEN '0.75'
                WHEN '92240A107' THEN '1.00'  WHEN '92240A108' THEN '1.50'
                WHEN '92240A109' THEN '2.00'  WHEN '92240A121' THEN '0.75'
                WHEN '92240A122' THEN '1.00'  WHEN '92240A123' THEN '1.50'
                WHEN '92240A124' THEN '2.00'  WHEN '92240A150' THEN '1.00'
                WHEN '92240A151' THEN '1.50'  WHEN '92240A152' THEN '2.00'
                WHEN '92240A153' THEN '3.00'  WHEN '92240A200' THEN '2.00'
            END,
            CASE v_sku.part_number
                WHEN '92240A105' THEN 0.50  WHEN '92240A106' THEN 0.75
                WHEN '92240A107' THEN 1.00  WHEN '92240A108' THEN 1.50
                WHEN '92240A109' THEN 2.00  WHEN '92240A121' THEN 0.75
                WHEN '92240A122' THEN 1.00  WHEN '92240A123' THEN 1.50
                WHEN '92240A124' THEN 2.00  WHEN '92240A150' THEN 1.00
                WHEN '92240A151' THEN 1.50  WHEN '92240A152' THEN 2.00
                WHEN '92240A153' THEN 3.00  WHEN '92240A200' THEN 2.00
            END)
        ON CONFLICT DO NOTHING;

        -- Material (same for all: zinc-plated)
        INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
        VALUES (v_sku.id, v_attr_mat, 'zinc-steel', v_opt_zinc)
        ON CONFLICT DO NOTHING;

        -- Grade
        INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
        VALUES (v_sku.id, v_attr_grade, 'grade-5', v_opt_grade5)
        ON CONFLICT DO NOTHING;

        -- Thread type (UNC for all these)
        INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
        VALUES (v_sku.id, v_attr_ttype, 'UNC', v_opt_unc)
        ON CONFLICT DO NOTHING;

        -- Drive type (hex)
        INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
        VALUES (v_sku.id, v_attr_drive, 'hex', v_opt_hex)
        ON CONFLICT DO NOTHING;
    END LOOP;
END $$;


-- ── Price tiers ─────────────────────────────────────────────────────────────

-- 1/4"-20 screws
WITH s AS (SELECT id FROM skus WHERE part_number IN
    ('92240A105','92240A106','92240A107','92240A108','92240A109'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s
CROSS JOIN (VALUES
    (1,    24,   0.0960),
    (25,   99,   0.0744),
    (100,  499,  0.0660),
    (500,  NULL, 0.0528)
) AS t(mn, mx, p)
ON CONFLICT DO NOTHING;

-- 3/8"-16 screws
WITH s AS (SELECT id FROM skus WHERE part_number IN
    ('92240A121','92240A122','92240A123','92240A124'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s
CROSS JOIN (VALUES
    (1,    24,   0.1870),
    (25,   99,   0.1490),
    (100,  499,  0.1310),
    (500,  NULL, 0.1040)
) AS t(mn, mx, p)
ON CONFLICT DO NOTHING;

-- 1/2"-13 screws
WITH s AS (SELECT id FROM skus WHERE part_number IN
    ('92240A150','92240A151','92240A152','92240A153'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s
CROSS JOIN (VALUES
    (1,    24,   0.3520),
    (25,   99,   0.2860),
    (100,  499,  0.2530),
    (500,  NULL, 0.1980)
) AS t(mn, mx, p)
ON CONFLICT DO NOTHING;

-- 3/4"-10 screw
WITH s AS (SELECT id FROM skus WHERE part_number = '92240A200')
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s
CROSS JOIN (VALUES
    (1,   24,  1.2400),
    (25,  99,  0.9900),
    (100, NULL,0.8700)
) AS t(mn, mx, p)
ON CONFLICT DO NOTHING;

-- ── Simulate in_stock ───────────────────────────────────────────────────────
UPDATE skus SET in_stock = TRUE
WHERE part_number IN (
    '92240A105','92240A106','92240A107','92240A121',
    '92240A122','92240A150','92240A151','92240A152'
);
