-- ════════════════════════════════════════════════════════════════════════════
-- V10__representative_seed_data.sql
-- Representative product data across multiple leaf categories.
-- ════════════════════════════════════════════════════════════════════════════

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║ PART 1 — SHARED ATTRIBUTES                                         ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

-- Material at Fastening & Joining level (inherited by all children)
INSERT INTO attribute_definitions
    (category_id, key, label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, 'material', 'Material', 'enum', 'checkbox',
       TRUE, 1, TRUE, 10, 130, 'Base material and finish'
FROM categories c WHERE c.slug = 'fastening-joining';

INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT ad.id, v.val, v.dv, v.so
FROM attribute_definitions ad
JOIN categories c ON c.id = ad.category_id
CROSS JOIN (VALUES
    ('zinc-steel',  'Zinc-Plated Steel',    1),
    ('18-8-ss',     '18-8 Stainless Steel', 2),
    ('316-ss',      '316 Stainless Steel',  3),
    ('plain-steel', 'Plain Steel',          4),
    ('brass',       'Brass',                5),
    ('nylon',       'Nylon',                6),
    ('alloy-steel', 'Alloy Steel',          7)
) AS v(val, dv, so)
WHERE ad.key = 'material' AND c.slug = 'fastening-joining';

-- Material at Plumbing level
INSERT INTO attribute_definitions
    (category_id, key, label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, 'material', 'Material', 'enum', 'checkbox',
       TRUE, 1, TRUE, 10, 130, 'Valve body material'
FROM categories c WHERE c.slug = 'plumbing';

INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT ad.id, v.val, v.dv, v.so
FROM attribute_definitions ad
JOIN categories c ON c.id = ad.category_id
CROSS JOIN (VALUES
    ('brass',        'Brass',               1),
    ('316-ss',       '316 Stainless Steel', 2),
    ('carbon-steel', 'Carbon Steel',        3),
    ('pvc',          'PVC',                 4),
    ('bronze',       'Bronze',              5)
) AS v(val, dv, so)
WHERE ad.key = 'material' AND c.slug = 'plumbing';


-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║ PART 2 — HEX HEAD CAP SCREWS                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

-- Leaf-level attributes
INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('thread_size', 'Thread Size',     NULL,  'enum',   'checkbox', TRUE,  2, TRUE,  1, 130, 'Nominal diameter x pitch'),
    ('length_in',   'Length',          'in.', 'number', 'range',    TRUE,  3, TRUE,  2, 100, 'Under-head to tip'),
    ('drive_type',  'Drive Type',     NULL,  'enum',   'checkbox', TRUE,  4, TRUE,  3, 100, 'Tool required to install'),
    ('grade',       'Grade',          NULL,  'enum',   'checkbox', TRUE,  5, TRUE,  4, 110, 'Strength grade'),
    ('thread_type', 'Thread Type',    NULL,  'enum',   'checkbox', TRUE,  6, TRUE,  5, 100, 'Coarse (UNC) or Fine (UNF)')
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'hex-head-cap-screws';

-- Thread size options
WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='thread_size' AND c.slug='hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('1/4-20',  '1/4"-20',   1), ('1/4-28',  '1/4"-28',   2),
    ('5/16-18', '5/16"-18',  3), ('3/8-16',  '3/8"-16',   4),
    ('3/8-24',  '3/8"-24',   5), ('1/2-13',  '1/2"-13',   6),
    ('1/2-20',  '1/2"-20',   7), ('5/8-11',  '5/8"-11',   8),
    ('3/4-10',  '3/4"-10',   9)
) AS v(val, dv, so);

-- Drive type options
WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='drive_type' AND c.slug='hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('hex',    'Hex (Wrench)', 1),
    ('socket', 'Hex Socket',   2),
    ('torx',   'Torx',         3)
) AS v(val, dv, so);

-- Grade options
WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='grade' AND c.slug='hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('grade-2',   'Grade 2',            1),
    ('grade-5',   'Grade 5',            2),
    ('grade-8',   'Grade 8',            3),
    ('class-8-8', 'Class 8.8 (Metric)', 4),
    ('class-10-9','Class 10.9 (Metric)',5)
) AS v(val, dv, so);

-- Thread type options
WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='thread_type' AND c.slug='hex-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('UNC',    'Coarse (UNC)', 1),
    ('UNF',    'Fine (UNF)',   2),
    ('metric', 'Metric',       3)
) AS v(val, dv, so);

-- Product groups
INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, engineering_note, default_sort_key)
SELECT c.id, v.nm, v.sub, v.slg, v.descr, v.eng, 'thread_size'
FROM categories c, (VALUES
    ('Hex Head Cap Screws', 'Zinc-Plated Steel',
     'hex-head-cap-screws-zinc-plated-steel',
     'General-purpose hex head cap screws. Zinc plating provides mild corrosion protection. Full threads, 2A tolerance.',
     'Tightening torque (dry): 1/4"-20 = 8 ft-lb, 3/8"-16 = 31 ft-lb, 1/2"-13 = 75 ft-lb.'),
    ('Hex Head Cap Screws', '18-8 Stainless Steel',
     'hex-head-cap-screws-18-8-stainless-steel',
     'Corrosion-resistant hex head cap screws in 18-8 stainless steel. Suitable for outdoor and food-processing environments.',
     'Do not use in chloride-rich or submerged marine environments; choose 316 SS instead.')
) AS v(nm, sub, slg, descr, eng)
WHERE c.slug = 'hex-head-cap-screws';

-- Column configs (both groups get same columns from leaf + ancestors)
WITH groups AS (SELECT id FROM product_groups WHERE slug LIKE 'hex-head-cap-screws-%')
INSERT INTO product_group_columns (product_group_id, attribute_id, role, sort_order)
SELECT g.id, ad.id,
    CASE ad.key WHEN 'thread_size' THEN 'sort_primary' WHEN 'length_in' THEN 'sort_secondary' ELSE 'column' END,
    ad.table_sort_order
FROM groups g
CROSS JOIN attribute_definitions ad
WHERE ad.category_id IN (
    SELECT c.id FROM categories c
    WHERE c.path @> (SELECT path FROM categories WHERE slug='hex-head-cap-screws')
)
AND ad.is_active = TRUE AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE);

-- SKUs (Zinc group)
WITH pg AS (SELECT id FROM product_groups WHERE slug = 'hex-head-cap-screws-zinc-plated-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('92240A105','1/4"-20 x 1/2" Hex Cap Screw, Zinc-Plated Steel',    0.0021),
    ('92240A106','1/4"-20 x 3/4" Hex Cap Screw, Zinc-Plated Steel',    0.0029),
    ('92240A107','1/4"-20 x 1" Hex Cap Screw, Zinc-Plated Steel',      0.0037),
    ('92240A108','1/4"-20 x 1-1/2" Hex Cap Screw, Zinc-Plated Steel',  0.0054),
    ('92240A109','1/4"-20 x 2" Hex Cap Screw, Zinc-Plated Steel',      0.0072),
    ('92240A121','3/8"-16 x 3/4" Hex Cap Screw, Zinc-Plated Steel',    0.0082),
    ('92240A122','3/8"-16 x 1" Hex Cap Screw, Zinc-Plated Steel',      0.0101),
    ('92240A123','3/8"-16 x 1-1/2" Hex Cap Screw, Zinc-Plated Steel',  0.0140),
    ('92240A124','3/8"-16 x 2" Hex Cap Screw, Zinc-Plated Steel',      0.0180),
    ('92240A150','1/2"-13 x 1" Hex Cap Screw, Zinc-Plated Steel',      0.0197),
    ('92240A151','1/2"-13 x 1-1/2" Hex Cap Screw, Zinc-Plated Steel',  0.0271),
    ('92240A152','1/2"-13 x 2" Hex Cap Screw, Zinc-Plated Steel',      0.0344),
    ('92240A153','1/2"-13 x 3" Hex Cap Screw, Zinc-Plated Steel',      0.0496),
    ('92240A200','3/4"-10 x 2" Hex Cap Screw, Zinc-Plated Steel',      0.0900)
) AS s(pn, nm, wt);

-- SKUs (18-8 SS group)
WITH pg AS (SELECT id FROM product_groups WHERE slug = 'hex-head-cap-screws-18-8-stainless-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('92188A105','1/4"-20 x 1/2" Hex Cap Screw, 18-8 Stainless',   0.0022),
    ('92188A106','1/4"-20 x 3/4" Hex Cap Screw, 18-8 Stainless',   0.0030),
    ('92188A107','1/4"-20 x 1" Hex Cap Screw, 18-8 Stainless',     0.0038),
    ('92188A110','1/4"-28 x 3/4" Hex Cap Screw, 18-8 Stainless',   0.0029),
    ('92188A111','1/4"-28 x 1" Hex Cap Screw, 18-8 Stainless',     0.0037),
    ('92188A121','3/8"-16 x 3/4" Hex Cap Screw, 18-8 Stainless',   0.0085),
    ('92188A122','3/8"-16 x 1" Hex Cap Screw, 18-8 Stainless',     0.0104),
    ('92188A123','3/8"-16 x 1-1/2" Hex Cap Screw, 18-8 Stainless', 0.0143),
    ('92188A150','1/2"-13 x 1" Hex Cap Screw, 18-8 Stainless',     0.0201),
    ('92188A151','1/2"-13 x 1-1/2" Hex Cap Screw, 18-8 Stainless', 0.0278)
) AS s(pn, nm, wt);

-- SKU Attributes (Hex Head Cap Screws — both groups)
DO $$
DECLARE
    v_cat_id INT; v_fj_id INT;
    v_ts INT; v_len INT; v_mat INT; v_grade INT; v_ttype INT; v_drive INT;
BEGIN
    SELECT id INTO v_cat_id FROM categories WHERE slug = 'hex-head-cap-screws';
    SELECT id INTO v_fj_id  FROM categories WHERE slug = 'fastening-joining';
    SELECT id INTO v_ts    FROM attribute_definitions WHERE key='thread_size' AND category_id=v_cat_id;
    SELECT id INTO v_len   FROM attribute_definitions WHERE key='length_in'   AND category_id=v_cat_id;
    SELECT id INTO v_mat   FROM attribute_definitions WHERE key='material'    AND category_id=v_fj_id;
    SELECT id INTO v_grade FROM attribute_definitions WHERE key='grade'       AND category_id=v_cat_id;
    SELECT id INTO v_ttype FROM attribute_definitions WHERE key='thread_type' AND category_id=v_cat_id;
    SELECT id INTO v_drive FROM attribute_definitions WHERE key='drive_type'  AND category_id=v_cat_id;

    -- ── ZINC GROUP — uniform attrs ──
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, 'zinc-steel', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='zinc-steel')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-head-cap-screws-zinc-plated-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_grade, 'grade-5', (SELECT id FROM attribute_options WHERE attribute_id=v_grade AND value='grade-5')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-head-cap-screws-zinc-plated-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ttype, 'UNC', (SELECT id FROM attribute_options WHERE attribute_id=v_ttype AND value='UNC')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-head-cap-screws-zinc-plated-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_drive, 'hex', (SELECT id FROM attribute_options WHERE attribute_id=v_drive AND value='hex')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-head-cap-screws-zinc-plated-steel';

    -- Zinc thread_size (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ts, v.ts, ao.id FROM (VALUES
        ('92240A105','1/4-20'),('92240A106','1/4-20'),('92240A107','1/4-20'),('92240A108','1/4-20'),('92240A109','1/4-20'),
        ('92240A121','3/8-16'),('92240A122','3/8-16'),('92240A123','3/8-16'),('92240A124','3/8-16'),
        ('92240A150','1/2-13'),('92240A151','1/2-13'),('92240A152','1/2-13'),('92240A153','1/2-13'),
        ('92240A200','3/4-10')
    ) AS v(pn, ts) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ts AND ao.value=v.ts;

    -- Zinc length_in (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_len, v.lt, v.ln FROM (VALUES
        ('92240A105','0.50',0.50),('92240A106','0.75',0.75),('92240A107','1.00',1.00),
        ('92240A108','1.50',1.50),('92240A109','2.00',2.00),
        ('92240A121','0.75',0.75),('92240A122','1.00',1.00),('92240A123','1.50',1.50),('92240A124','2.00',2.00),
        ('92240A150','1.00',1.00),('92240A151','1.50',1.50),('92240A152','2.00',2.00),('92240A153','3.00',3.00),
        ('92240A200','2.00',2.00)
    ) AS v(pn, lt, ln) JOIN skus s ON s.part_number=v.pn;

    -- ── 18-8 SS GROUP — uniform attrs ──
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, '18-8-ss', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='18-8-ss')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-head-cap-screws-18-8-stainless-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_drive, 'hex', (SELECT id FROM attribute_options WHERE attribute_id=v_drive AND value='hex')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-head-cap-screws-18-8-stainless-steel';

    -- SS thread_size (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ts, v.ts, ao.id FROM (VALUES
        ('92188A105','1/4-20'),('92188A106','1/4-20'),('92188A107','1/4-20'),
        ('92188A110','1/4-28'),('92188A111','1/4-28'),
        ('92188A121','3/8-16'),('92188A122','3/8-16'),('92188A123','3/8-16'),
        ('92188A150','1/2-13'),('92188A151','1/2-13')
    ) AS v(pn, ts) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ts AND ao.value=v.ts;

    -- SS thread_type (UNC for most, UNF for 1/4-28)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ttype, v.tt, ao.id FROM (VALUES
        ('92188A105','UNC'),('92188A106','UNC'),('92188A107','UNC'),
        ('92188A110','UNF'),('92188A111','UNF'),
        ('92188A121','UNC'),('92188A122','UNC'),('92188A123','UNC'),
        ('92188A150','UNC'),('92188A151','UNC')
    ) AS v(pn, tt) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ttype AND ao.value=v.tt;

    -- SS length_in (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_len, v.lt, v.ln FROM (VALUES
        ('92188A105','0.50',0.50),('92188A106','0.75',0.75),('92188A107','1.00',1.00),
        ('92188A110','0.75',0.75),('92188A111','1.00',1.00),
        ('92188A121','0.75',0.75),('92188A122','1.00',1.00),('92188A123','1.50',1.50),
        ('92188A150','1.00',1.00),('92188A151','1.50',1.50)
    ) AS v(pn, lt, ln) JOIN skus s ON s.part_number=v.pn;
END $$;

-- Price tiers (Zinc 1/4"-20)
WITH s AS (SELECT id FROM skus WHERE part_number IN ('92240A105','92240A106','92240A107','92240A108','92240A109'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.0960),(25, 99, 0.0744),(100, 499, 0.0660),(500, NULL, 0.0528)
) AS t(mn, mx, p);

-- Price tiers (Zinc 3/8"-16)
WITH s AS (SELECT id FROM skus WHERE part_number IN ('92240A121','92240A122','92240A123','92240A124'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.1870),(25, 99, 0.1490),(100, 499, 0.1310),(500, NULL, 0.1040)
) AS t(mn, mx, p);

-- Price tiers (Zinc 1/2"-13)
WITH s AS (SELECT id FROM skus WHERE part_number IN ('92240A150','92240A151','92240A152','92240A153'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.3520),(25, 99, 0.2860),(100, 499, 0.2530),(500, NULL, 0.1980)
) AS t(mn, mx, p);

-- Price tiers (Zinc 3/4"-10)
WITH s AS (SELECT id FROM skus WHERE part_number = '92240A200')
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 1.2400),(25, 99, 0.9900),(100, NULL, 0.8700)
) AS t(mn, mx, p);

-- Price tiers (18-8 SS 1/4")
WITH s AS (SELECT id FROM skus WHERE part_number IN ('92188A105','92188A106','92188A107','92188A110','92188A111'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.2340),(25, 99, 0.1870),(100, 499, 0.1650),(500, NULL, 0.1320)
) AS t(mn, mx, p);

-- Price tiers (18-8 SS 3/8")
WITH s AS (SELECT id FROM skus WHERE part_number IN ('92188A121','92188A122','92188A123'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.4560),(25, 99, 0.3640),(100, 499, 0.3200),(500, NULL, 0.2560)
) AS t(mn, mx, p);

-- Price tiers (18-8 SS 1/2")
WITH s AS (SELECT id FROM skus WHERE part_number IN ('92188A150','92188A151'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.8590),(25, 99, 0.6870),(100, 499, 0.6080),(500, NULL, 0.4860)
) AS t(mn, mx, p);

-- In-stock flags
UPDATE skus SET in_stock = TRUE WHERE part_number IN (
    '92240A105','92240A106','92240A107','92240A121','92240A122',
    '92240A150','92240A151','92240A152',
    '92188A105','92188A106','92188A107','92188A121','92188A122','92188A150'
);


-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║ PART 3 — SOCKET HEAD CAP SCREWS                                     ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('thread_size', 'Thread Size', NULL,  'enum',   'checkbox', TRUE,  2, TRUE,  1, 130, 'Nominal diameter x pitch'),
    ('length_in',   'Length',      'in.', 'number', 'range',    TRUE,  3, TRUE,  2, 100, 'Under-head to tip'),
    ('drive_type',  'Drive Type',  NULL,  'enum',   'checkbox', FALSE, 99,TRUE,  3, 100, 'Tool required to install'),
    ('grade',       'Grade',       NULL,  'enum',   'checkbox', TRUE,  4, TRUE,  4, 130, 'Strength class'),
    ('thread_type', 'Thread Type', NULL,  'enum',   'checkbox', TRUE,  5, TRUE,  5, 100, 'Coarse (UNC) or Fine (UNF)')
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'socket-head-cap-screws';

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='thread_size' AND c.slug='socket-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('#6-32',   '#6-32',     1), ('#8-32',   '#8-32',     2),
    ('#10-24',  '#10-24',    3), ('#10-32',  '#10-32',    4),
    ('1/4-20',  '1/4"-20',   5), ('1/4-28',  '1/4"-28',   6),
    ('5/16-18', '5/16"-18',  7), ('3/8-16',  '3/8"-16',   8),
    ('1/2-13',  '1/2"-13',   9)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='drive_type' AND c.slug='socket-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('hex-socket', 'Hex Socket', 1),
    ('torx',       'Torx',       2)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='grade' AND c.slug='socket-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('class-12-9', 'Class 12.9', 1),
    ('class-10-9', 'Class 10.9', 2),
    ('18-8-ss',    '18-8 SS',    3)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='thread_type' AND c.slug='socket-head-cap-screws')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('UNC', 'Coarse (UNC)', 1),
    ('UNF', 'Fine (UNF)',   2)
) AS v(val, dv, so);

-- Product group
INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, engineering_note, default_sort_key)
SELECT c.id,
    'Socket Head Cap Screws', 'Alloy Steel, Black Oxide',
    'socket-head-cap-screws-alloy-steel',
    'High-strength socket head cap screws in alloy steel with black oxide finish. Class 12.9 rated. Driven with hex (Allen) key.',
    'Socket head cap screws are preferred where high clamping force and compact head profile are needed.',
    'thread_size'
FROM categories c WHERE c.slug = 'socket-head-cap-screws';

-- Column config
WITH pg AS (SELECT id FROM product_groups WHERE slug = 'socket-head-cap-screws-alloy-steel')
INSERT INTO product_group_columns (product_group_id, attribute_id, role, sort_order)
SELECT pg.id, ad.id,
    CASE ad.key WHEN 'thread_size' THEN 'sort_primary' WHEN 'length_in' THEN 'sort_secondary' ELSE 'column' END,
    ad.table_sort_order
FROM pg
CROSS JOIN attribute_definitions ad
WHERE ad.category_id IN (
    SELECT c.id FROM categories c WHERE c.path @> (SELECT path FROM categories WHERE slug='socket-head-cap-screws')
) AND ad.is_active = TRUE AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE);

-- SKUs
WITH pg AS (SELECT id FROM product_groups WHERE slug = 'socket-head-cap-screws-alloy-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('91251A105','#10-32 x 1/2" Socket Head Cap Screw, Alloy Steel',    0.0015),
    ('91251A106','#10-32 x 3/4" Socket Head Cap Screw, Alloy Steel',    0.0020),
    ('91251A107','#10-32 x 1" Socket Head Cap Screw, Alloy Steel',      0.0026),
    ('91251A120','1/4"-20 x 1/2" Socket Head Cap Screw, Alloy Steel',   0.0028),
    ('91251A121','1/4"-20 x 3/4" Socket Head Cap Screw, Alloy Steel',   0.0036),
    ('91251A122','1/4"-20 x 1" Socket Head Cap Screw, Alloy Steel',     0.0045),
    ('91251A123','1/4"-20 x 1-1/2" Socket Head Cap Screw, Alloy Steel', 0.0062),
    ('91251A140','3/8"-16 x 3/4" Socket Head Cap Screw, Alloy Steel',   0.0095),
    ('91251A141','3/8"-16 x 1" Socket Head Cap Screw, Alloy Steel',     0.0118),
    ('91251A142','3/8"-16 x 1-1/2" Socket Head Cap Screw, Alloy Steel', 0.0163)
) AS s(pn, nm, wt);

-- SKU Attributes (Socket Head Cap Screws)
DO $$
DECLARE
    v_cat_id INT; v_fj_id INT;
    v_ts INT; v_len INT; v_mat INT; v_grade INT; v_ttype INT; v_drive INT;
BEGIN
    SELECT id INTO v_cat_id FROM categories WHERE slug = 'socket-head-cap-screws';
    SELECT id INTO v_fj_id  FROM categories WHERE slug = 'fastening-joining';
    SELECT id INTO v_ts    FROM attribute_definitions WHERE key='thread_size' AND category_id=v_cat_id;
    SELECT id INTO v_len   FROM attribute_definitions WHERE key='length_in'   AND category_id=v_cat_id;
    SELECT id INTO v_mat   FROM attribute_definitions WHERE key='material'    AND category_id=v_fj_id;
    SELECT id INTO v_grade FROM attribute_definitions WHERE key='grade'       AND category_id=v_cat_id;
    SELECT id INTO v_ttype FROM attribute_definitions WHERE key='thread_type' AND category_id=v_cat_id;
    SELECT id INTO v_drive FROM attribute_definitions WHERE key='drive_type'  AND category_id=v_cat_id;

    -- Uniform: alloy-steel, class-12-9, hex-socket
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, 'alloy-steel', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='alloy-steel')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='socket-head-cap-screws-alloy-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_grade, 'class-12-9', (SELECT id FROM attribute_options WHERE attribute_id=v_grade AND value='class-12-9')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='socket-head-cap-screws-alloy-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_drive, 'hex-socket', (SELECT id FROM attribute_options WHERE attribute_id=v_drive AND value='hex-socket')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='socket-head-cap-screws-alloy-steel';

    -- Thread size (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ts, v.ts, ao.id FROM (VALUES
        ('91251A105','#10-32'),('91251A106','#10-32'),('91251A107','#10-32'),
        ('91251A120','1/4-20'),('91251A121','1/4-20'),('91251A122','1/4-20'),('91251A123','1/4-20'),
        ('91251A140','3/8-16'),('91251A141','3/8-16'),('91251A142','3/8-16')
    ) AS v(pn, ts) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ts AND ao.value=v.ts;

    -- Thread type (#10-32 = UNF, others = UNC)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ttype, v.tt, ao.id FROM (VALUES
        ('91251A105','UNF'),('91251A106','UNF'),('91251A107','UNF'),
        ('91251A120','UNC'),('91251A121','UNC'),('91251A122','UNC'),('91251A123','UNC'),
        ('91251A140','UNC'),('91251A141','UNC'),('91251A142','UNC')
    ) AS v(pn, tt) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ttype AND ao.value=v.tt;

    -- Length (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_len, v.lt, v.ln FROM (VALUES
        ('91251A105','0.50',0.50),('91251A106','0.75',0.75),('91251A107','1.00',1.00),
        ('91251A120','0.50',0.50),('91251A121','0.75',0.75),('91251A122','1.00',1.00),('91251A123','1.50',1.50),
        ('91251A140','0.75',0.75),('91251A141','1.00',1.00),('91251A142','1.50',1.50)
    ) AS v(pn, lt, ln) JOIN skus s ON s.part_number=v.pn;
END $$;

-- Price tiers (Socket #10-32)
WITH s AS (SELECT id FROM skus WHERE part_number IN ('91251A105','91251A106','91251A107'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.1520),(25, 99, 0.1220),(100, NULL, 0.0980)
) AS t(mn, mx, p);

-- Price tiers (Socket 1/4"-20)
WITH s AS (SELECT id FROM skus WHERE part_number IN ('91251A120','91251A121','91251A122','91251A123'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.2180),(25, 99, 0.1740),(100, NULL, 0.1450)
) AS t(mn, mx, p);

-- Price tiers (Socket 3/8"-16)
WITH s AS (SELECT id FROM skus WHERE part_number IN ('91251A140','91251A141','91251A142'))
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx, t.p FROM s CROSS JOIN (VALUES
    (1, 24, 0.4480),(25, 99, 0.3580),(100, NULL, 0.2990)
) AS t(mn, mx, p);

UPDATE skus SET in_stock = TRUE WHERE part_number IN (
    '91251A105','91251A106','91251A120','91251A121','91251A122',
    '91251A140','91251A141'
);


-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║ PART 4 — HEX NUTS                                                  ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('thread_size', 'Thread Size',        NULL,  'enum',   'checkbox', TRUE,  2, TRUE,  1, 130, 'Matching bolt thread size'),
    ('width_af',    'Width Across Flats', 'in.', 'number', 'range',    TRUE,  3, TRUE,  2, 120, 'Wrench size'),
    ('height_in',   'Height',             'in.', 'number', 'range',    TRUE,  4, TRUE,  3, 100, 'Nut height'),
    ('thread_type', 'Thread Type',        NULL,  'enum',   'checkbox', TRUE,  5, TRUE,  4, 100, 'Coarse (UNC) or Fine (UNF)')
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'hex-nuts';

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='thread_size' AND c.slug='hex-nuts')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('1/4-20',  '1/4"-20',  1), ('5/16-18', '5/16"-18', 2),
    ('3/8-16',  '3/8"-16',  3), ('1/2-13',  '1/2"-13',  4),
    ('5/8-11',  '5/8"-11',  5), ('3/4-10',  '3/4"-10',  6)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='thread_type' AND c.slug='hex-nuts')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('UNC', 'Coarse (UNC)', 1),
    ('UNF', 'Fine (UNF)',   2)
) AS v(val, dv, so);

-- Product groups
INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, default_sort_key)
SELECT c.id, v.nm, v.sub, v.slg, v.descr, 'thread_size'
FROM categories c, (VALUES
    ('Hex Nuts', 'Zinc-Plated Steel, Grade 5',
     'hex-nuts-zinc-plated-steel',
     'Standard hex nuts in zinc-plated steel. Grade 5 strength. Use with matching bolts and cap screws.'),
    ('Hex Nuts', '18-8 Stainless Steel',
     'hex-nuts-18-8-stainless-steel',
     'Corrosion-resistant hex nuts in 18-8 stainless steel. For outdoor, food-processing, and marine applications.')
) AS v(nm, sub, slg, descr)
WHERE c.slug = 'hex-nuts';

-- Column configs
WITH groups AS (SELECT id FROM product_groups WHERE slug LIKE 'hex-nuts-%')
INSERT INTO product_group_columns (product_group_id, attribute_id, role, sort_order)
SELECT g.id, ad.id,
    CASE ad.key WHEN 'thread_size' THEN 'sort_primary' ELSE 'column' END,
    ad.table_sort_order
FROM groups g
CROSS JOIN attribute_definitions ad
WHERE ad.category_id IN (
    SELECT c.id FROM categories c WHERE c.path @> (SELECT path FROM categories WHERE slug='hex-nuts')
) AND ad.is_active = TRUE AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE);

-- SKUs (Zinc nuts)
WITH pg AS (SELECT id FROM product_groups WHERE slug = 'hex-nuts-zinc-plated-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('95462A029','1/4"-20 Hex Nut, Zinc-Plated Steel',   0.0030),
    ('95462A031','5/16"-18 Hex Nut, Zinc-Plated Steel',  0.0050),
    ('95462A033','3/8"-16 Hex Nut, Zinc-Plated Steel',   0.0080),
    ('95462A035','1/2"-13 Hex Nut, Zinc-Plated Steel',   0.0170),
    ('95462A037','5/8"-11 Hex Nut, Zinc-Plated Steel',   0.0330),
    ('95462A039','3/4"-10 Hex Nut, Zinc-Plated Steel',   0.0540)
) AS s(pn, nm, wt);

-- SKUs (18-8 SS nuts)
WITH pg AS (SELECT id FROM product_groups WHERE slug = 'hex-nuts-18-8-stainless-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('94804A029','1/4"-20 Hex Nut, 18-8 Stainless Steel',   0.0031),
    ('94804A031','5/16"-18 Hex Nut, 18-8 Stainless Steel',  0.0052),
    ('94804A033','3/8"-16 Hex Nut, 18-8 Stainless Steel',   0.0083),
    ('94804A035','1/2"-13 Hex Nut, 18-8 Stainless Steel',   0.0175),
    ('94804A037','5/8"-11 Hex Nut, 18-8 Stainless Steel',   0.0340)
) AS s(pn, nm, wt);

-- SKU Attributes (Hex Nuts)
DO $$
DECLARE
    v_cat_id INT; v_fj_id INT;
    v_ts INT; v_waf INT; v_ht INT; v_mat INT; v_ttype INT;
BEGIN
    SELECT id INTO v_cat_id FROM categories WHERE slug = 'hex-nuts';
    SELECT id INTO v_fj_id  FROM categories WHERE slug = 'fastening-joining';
    SELECT id INTO v_ts    FROM attribute_definitions WHERE key='thread_size' AND category_id=v_cat_id;
    SELECT id INTO v_waf   FROM attribute_definitions WHERE key='width_af'    AND category_id=v_cat_id;
    SELECT id INTO v_ht    FROM attribute_definitions WHERE key='height_in'   AND category_id=v_cat_id;
    SELECT id INTO v_mat   FROM attribute_definitions WHERE key='material'    AND category_id=v_fj_id;
    SELECT id INTO v_ttype FROM attribute_definitions WHERE key='thread_type' AND category_id=v_cat_id;

    -- ── ZINC NUTS — uniform: zinc-steel, UNC ──
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, 'zinc-steel', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='zinc-steel')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-nuts-zinc-plated-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ttype, 'UNC', (SELECT id FROM attribute_options WHERE attribute_id=v_ttype AND value='UNC')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-nuts-zinc-plated-steel';

    -- Zinc thread_size
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ts, v.ts, ao.id FROM (VALUES
        ('95462A029','1/4-20'),('95462A031','5/16-18'),('95462A033','3/8-16'),
        ('95462A035','1/2-13'),('95462A037','5/8-11'),('95462A039','3/4-10')
    ) AS v(pn, ts) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ts AND ao.value=v.ts;

    -- Zinc width_af
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_waf, v.vt, v.vn FROM (VALUES
        ('95462A029','0.438',0.438),('95462A031','0.500',0.500),('95462A033','0.563',0.563),
        ('95462A035','0.750',0.750),('95462A037','0.938',0.938),('95462A039','1.125',1.125)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;

    -- Zinc height_in
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_ht, v.vt, v.vn FROM (VALUES
        ('95462A029','0.219',0.219),('95462A031','0.266',0.266),('95462A033','0.328',0.328),
        ('95462A035','0.438',0.438),('95462A037','0.547',0.547),('95462A039','0.641',0.641)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;

    -- ── 18-8 SS NUTS — uniform: 18-8-ss, UNC ──
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, '18-8-ss', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='18-8-ss')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-nuts-18-8-stainless-steel';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ttype, 'UNC', (SELECT id FROM attribute_options WHERE attribute_id=v_ttype AND value='UNC')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='hex-nuts-18-8-stainless-steel';

    -- SS thread_size
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ts, v.ts, ao.id FROM (VALUES
        ('94804A029','1/4-20'),('94804A031','5/16-18'),('94804A033','3/8-16'),
        ('94804A035','1/2-13'),('94804A037','5/8-11')
    ) AS v(pn, ts) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ts AND ao.value=v.ts;

    -- SS width_af
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_waf, v.vt, v.vn FROM (VALUES
        ('94804A029','0.438',0.438),('94804A031','0.500',0.500),('94804A033','0.563',0.563),
        ('94804A035','0.750',0.750),('94804A037','0.938',0.938)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;

    -- SS height_in
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_ht, v.vt, v.vn FROM (VALUES
        ('94804A029','0.219',0.219),('94804A031','0.266',0.266),('94804A033','0.328',0.328),
        ('94804A035','0.438',0.438),('94804A037','0.547',0.547)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;
END $$;

-- Price tiers (Zinc nuts)
WITH s AS (SELECT id, part_number FROM skus WHERE part_number LIKE '95462A%')
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx,
    CASE s.part_number
        WHEN '95462A029' THEN t.p * 1.0
        WHEN '95462A031' THEN t.p * 1.2
        WHEN '95462A033' THEN t.p * 1.6
        WHEN '95462A035' THEN t.p * 2.7
        WHEN '95462A037' THEN t.p * 5.1
        WHEN '95462A039' THEN t.p * 8.3
    END
FROM s CROSS JOIN (VALUES
    (1, 99, 0.0350),(100, 499, 0.0280),(500, NULL, 0.0220)
) AS t(mn, mx, p);

-- Price tiers (SS nuts — ~2.5x zinc)
WITH s AS (SELECT id, part_number FROM skus WHERE part_number LIKE '94804A%')
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx,
    CASE s.part_number
        WHEN '94804A029' THEN t.p * 1.0
        WHEN '94804A031' THEN t.p * 1.2
        WHEN '94804A033' THEN t.p * 1.6
        WHEN '94804A035' THEN t.p * 2.7
        WHEN '94804A037' THEN t.p * 5.1
    END
FROM s CROSS JOIN (VALUES
    (1, 99, 0.0850),(100, 499, 0.0680),(500, NULL, 0.0540)
) AS t(mn, mx, p);

UPDATE skus SET in_stock = TRUE WHERE part_number IN (
    '95462A029','95462A031','95462A033','95462A035','95462A037',
    '94804A029','94804A031','94804A033','94804A035'
);


-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║ PART 5 — FLAT WASHERS                                               ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('bolt_size',    'For Bolt Size', NULL,  'enum',   'checkbox', TRUE,  2, TRUE,  1, 120, 'Bolt size this washer fits'),
    ('id_in',        'ID',           'in.', 'number', 'range',    TRUE,  3, TRUE,  2, 90,  'Inner diameter'),
    ('od_in',        'OD',           'in.', 'number', 'range',    TRUE,  4, TRUE,  3, 90,  'Outer diameter'),
    ('thickness_in', 'Thickness',    'in.', 'number', 'range',    TRUE,  5, TRUE,  4, 100, 'Washer thickness')
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'flat-washers';

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='bolt_size' AND c.slug='flat-washers')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('#10',  '#10',    1), ('1/4',  '1/4"',   2), ('5/16', '5/16"',  3),
    ('3/8',  '3/8"',   4), ('1/2',  '1/2"',   5), ('5/8',  '5/8"',   6),
    ('3/4',  '3/4"',   7), ('1',    '1"',     8)
) AS v(val, dv, so);

INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, default_sort_key)
SELECT c.id,
    'Flat Washers', 'Zinc-Plated Steel',
    'flat-washers-zinc-plated-steel',
    'General-purpose flat washers per USS standard. Zinc plating for mild corrosion protection. Distributes load and protects surfaces.',
    'bolt_size'
FROM categories c WHERE c.slug = 'flat-washers';

WITH pg AS (SELECT id FROM product_groups WHERE slug = 'flat-washers-zinc-plated-steel')
INSERT INTO product_group_columns (product_group_id, attribute_id, role, sort_order)
SELECT pg.id, ad.id,
    CASE ad.key WHEN 'bolt_size' THEN 'sort_primary' ELSE 'column' END,
    ad.table_sort_order
FROM pg
CROSS JOIN attribute_definitions ad
WHERE ad.category_id IN (
    SELECT c.id FROM categories c WHERE c.path @> (SELECT path FROM categories WHERE slug='flat-washers')
) AND ad.is_active = TRUE AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE);

WITH pg AS (SELECT id FROM product_groups WHERE slug = 'flat-washers-zinc-plated-steel')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('90126A009','#10 Flat Washer, Zinc-Plated Steel',    0.0008),
    ('90126A029','1/4" Flat Washer, Zinc-Plated Steel',   0.0014),
    ('90126A031','5/16" Flat Washer, Zinc-Plated Steel',  0.0020),
    ('90126A033','3/8" Flat Washer, Zinc-Plated Steel',   0.0028),
    ('90126A035','1/2" Flat Washer, Zinc-Plated Steel',   0.0060),
    ('90126A037','5/8" Flat Washer, Zinc-Plated Steel',   0.0100),
    ('90126A039','3/4" Flat Washer, Zinc-Plated Steel',   0.0150),
    ('90126A041','1" Flat Washer, Zinc-Plated Steel',     0.0280)
) AS s(pn, nm, wt);

-- SKU Attributes (Flat Washers)
DO $$
DECLARE
    v_cat_id INT; v_fj_id INT;
    v_bs INT; v_id_attr INT; v_od INT; v_thk INT; v_mat INT;
BEGIN
    SELECT id INTO v_cat_id FROM categories WHERE slug = 'flat-washers';
    SELECT id INTO v_fj_id  FROM categories WHERE slug = 'fastening-joining';
    SELECT id INTO v_bs      FROM attribute_definitions WHERE key='bolt_size'    AND category_id=v_cat_id;
    SELECT id INTO v_id_attr FROM attribute_definitions WHERE key='id_in'        AND category_id=v_cat_id;
    SELECT id INTO v_od      FROM attribute_definitions WHERE key='od_in'        AND category_id=v_cat_id;
    SELECT id INTO v_thk     FROM attribute_definitions WHERE key='thickness_in' AND category_id=v_cat_id;
    SELECT id INTO v_mat     FROM attribute_definitions WHERE key='material'     AND category_id=v_fj_id;

    -- Material: zinc-steel for all
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, 'zinc-steel', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='zinc-steel')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='flat-washers-zinc-plated-steel';

    -- Bolt size
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_bs, v.bs, ao.id FROM (VALUES
        ('90126A009','#10'),('90126A029','1/4'),('90126A031','5/16'),('90126A033','3/8'),
        ('90126A035','1/2'),('90126A037','5/8'),('90126A039','3/4'),('90126A041','1')
    ) AS v(pn, bs) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_bs AND ao.value=v.bs;

    -- ID
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_id_attr, v.vt, v.vn FROM (VALUES
        ('90126A009','0.203',0.203),('90126A029','0.281',0.281),('90126A031','0.344',0.344),
        ('90126A033','0.406',0.406),('90126A035','0.531',0.531),('90126A037','0.656',0.656),
        ('90126A039','0.812',0.812),('90126A041','1.062',1.062)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;

    -- OD
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_od, v.vt, v.vn FROM (VALUES
        ('90126A009','0.500',0.500),('90126A029','0.625',0.625),('90126A031','0.688',0.688),
        ('90126A033','0.812',0.812),('90126A035','1.062',1.062),('90126A037','1.312',1.312),
        ('90126A039','1.469',1.469),('90126A041','2.000',2.000)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;

    -- Thickness
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_thk, v.vt, v.vn FROM (VALUES
        ('90126A009','0.049',0.049),('90126A029','0.065',0.065),('90126A031','0.065',0.065),
        ('90126A033','0.065',0.065),('90126A035','0.095',0.095),('90126A037','0.095',0.095),
        ('90126A039','0.134',0.134),('90126A041','0.134',0.134)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;
END $$;

-- Price tiers (Flat Washers)
WITH s AS (SELECT id, part_number FROM skus WHERE part_number LIKE '90126A%')
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx,
    CASE s.part_number
        WHEN '90126A009' THEN t.p * 1.0
        WHEN '90126A029' THEN t.p * 1.3
        WHEN '90126A031' THEN t.p * 1.5
        WHEN '90126A033' THEN t.p * 1.8
        WHEN '90126A035' THEN t.p * 2.5
        WHEN '90126A037' THEN t.p * 3.8
        WHEN '90126A039' THEN t.p * 5.2
        WHEN '90126A041' THEN t.p * 8.0
    END
FROM s CROSS JOIN (VALUES
    (1, 99, 0.0150),(100, 499, 0.0120),(500, NULL, 0.0095)
) AS t(mn, mx, p);

UPDATE skus SET in_stock = TRUE WHERE part_number LIKE '90126A%';


-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║ PART 6 — BALL VALVES (Plumbing)                                     ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
    ('pipe_size',        'Pipe Size',        NULL,  'enum',   'checkbox', TRUE,  2, TRUE,  1, 120, 'NPT pipe size'),
    ('connection_type',  'Connection Type',  NULL,  'enum',   'checkbox', TRUE,  3, TRUE,  2, 140, 'How valve connects to pipe'),
    ('port_type',        'Port Type',        NULL,  'enum',   'checkbox', TRUE,  4, TRUE,  3, 120, 'Full or standard port'),
    ('max_pressure_psi', 'Max Pressure',     'psi', 'number', 'range',    TRUE,  5, TRUE,  4, 120, 'Maximum working pressure (WOG)'),
    ('handle_type',      'Handle Type',      NULL,  'enum',   'checkbox', TRUE,  6, TRUE,  5, 110, 'Lever or T-handle')
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = 'ball-valves';

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='pipe_size' AND c.slug='ball-valves')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('1/4',   '1/4"',    1), ('3/8',   '3/8"',    2),
    ('1/2',   '1/2"',    3), ('3/4',   '3/4"',    4),
    ('1',     '1"',      5), ('1-1/4', '1-1/4"',  6),
    ('1-1/2', '1-1/2"',  7), ('2',     '2"',      8)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='connection_type' AND c.slug='ball-valves')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('npt-threaded', 'NPT Threaded', 1),
    ('solder',       'Solder',       2),
    ('press-fit',    'Press-Fit',    3)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='port_type' AND c.slug='ball-valves')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('full-port',     'Full Port',     1),
    ('standard-port', 'Standard Port', 2)
) AS v(val, dv, so);

WITH attr AS (SELECT ad.id FROM attribute_definitions ad JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='handle_type' AND c.slug='ball-valves')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
    ('lever',    'Lever',    1),
    ('t-handle', 'T-Handle', 2)
) AS v(val, dv, so);

INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, engineering_note, default_sort_key)
SELECT c.id,
    'Ball Valves', 'Brass, Full Port, NPT',
    'ball-valves-brass-full-port',
    'Full-port brass ball valves with NPT threaded connections. Chrome-plated brass ball, PTFE seats. Suitable for water, oil, gas, and steam.',
    'Full-port design provides unrestricted flow equal to pipe diameter. Max temp 400 F (steam), 250 F (water).',
    'pipe_size'
FROM categories c WHERE c.slug = 'ball-valves';

WITH pg AS (SELECT id FROM product_groups WHERE slug = 'ball-valves-brass-full-port')
INSERT INTO product_group_columns (product_group_id, attribute_id, role, sort_order)
SELECT pg.id, ad.id,
    CASE ad.key WHEN 'pipe_size' THEN 'sort_primary' ELSE 'column' END,
    ad.table_sort_order
FROM pg
CROSS JOIN attribute_definitions ad
WHERE ad.category_id IN (
    SELECT c.id FROM categories c WHERE c.path @> (SELECT path FROM categories WHERE slug='ball-valves')
) AND ad.is_active = TRUE AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE);

WITH pg AS (SELECT id FROM product_groups WHERE slug = 'ball-valves-brass-full-port')
INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
SELECT pg.id, s.pn, s.nm, 'Each', 1, s.wt FROM pg, (VALUES
    ('47865T101','1/4" Brass Ball Valve, Full Port, NPT',   0.19),
    ('47865T102','3/8" Brass Ball Valve, Full Port, NPT',   0.25),
    ('47865T103','1/2" Brass Ball Valve, Full Port, NPT',   0.38),
    ('47865T104','3/4" Brass Ball Valve, Full Port, NPT',   0.62),
    ('47865T105','1" Brass Ball Valve, Full Port, NPT',     1.10),
    ('47865T106','1-1/4" Brass Ball Valve, Full Port, NPT', 1.65)
) AS s(pn, nm, wt);

-- SKU Attributes (Ball Valves)
DO $$
DECLARE
    v_cat_id INT; v_plumb_id INT;
    v_ps INT; v_conn INT; v_port INT; v_pres INT; v_handle INT; v_mat INT;
BEGIN
    SELECT id INTO v_cat_id   FROM categories WHERE slug = 'ball-valves';
    SELECT id INTO v_plumb_id FROM categories WHERE slug = 'plumbing';
    SELECT id INTO v_ps     FROM attribute_definitions WHERE key='pipe_size'        AND category_id=v_cat_id;
    SELECT id INTO v_conn   FROM attribute_definitions WHERE key='connection_type'  AND category_id=v_cat_id;
    SELECT id INTO v_port   FROM attribute_definitions WHERE key='port_type'        AND category_id=v_cat_id;
    SELECT id INTO v_pres   FROM attribute_definitions WHERE key='max_pressure_psi' AND category_id=v_cat_id;
    SELECT id INTO v_handle FROM attribute_definitions WHERE key='handle_type'      AND category_id=v_cat_id;
    SELECT id INTO v_mat    FROM attribute_definitions WHERE key='material'         AND category_id=v_plumb_id;

    -- Uniform: brass, npt-threaded, full-port, lever
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat, 'brass', (SELECT id FROM attribute_options WHERE attribute_id=v_mat AND value='brass')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='ball-valves-brass-full-port';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_conn, 'npt-threaded', (SELECT id FROM attribute_options WHERE attribute_id=v_conn AND value='npt-threaded')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='ball-valves-brass-full-port';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_port, 'full-port', (SELECT id FROM attribute_options WHERE attribute_id=v_port AND value='full-port')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='ball-valves-brass-full-port';

    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_handle, 'lever', (SELECT id FROM attribute_options WHERE attribute_id=v_handle AND value='lever')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id WHERE pg.slug='ball-valves-brass-full-port';

    -- Pipe size (varies)
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_ps, v.ps, ao.id FROM (VALUES
        ('47865T101','1/4'),('47865T102','3/8'),('47865T103','1/2'),
        ('47865T104','3/4'),('47865T105','1'),('47865T106','1-1/4')
    ) AS v(pn, ps) JOIN skus s ON s.part_number=v.pn JOIN attribute_options ao ON ao.attribute_id=v_ps AND ao.value=v.ps;

    -- Max pressure (600 WOG for up to 1", 400 for 1-1/4")
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, v_pres, v.vt, v.vn FROM (VALUES
        ('47865T101','600',600.0),('47865T102','600',600.0),('47865T103','600',600.0),
        ('47865T104','600',600.0),('47865T105','600',600.0),('47865T106','400',400.0)
    ) AS v(pn, vt, vn) JOIN skus s ON s.part_number=v.pn;
END $$;

-- Price tiers (Ball Valves)
WITH s AS (SELECT id, part_number FROM skus WHERE part_number LIKE '47865T%')
INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
SELECT s.id, 'USD', t.mn, t.mx,
    CASE s.part_number
        WHEN '47865T101' THEN t.p
        WHEN '47865T102' THEN t.p * 1.15
        WHEN '47865T103' THEN t.p * 1.34
        WHEN '47865T104' THEN t.p * 1.67
        WHEN '47865T105' THEN t.p * 2.65
        WHEN '47865T106' THEN t.p * 4.09
    END
FROM s CROSS JOIN (VALUES
    (1, 9, 8.5000),(10, 49, 7.2000),(50, NULL, 6.1000)
) AS t(mn, mx, p);

UPDATE skus SET in_stock = TRUE WHERE part_number IN (
    '47865T101','47865T102','47865T103','47865T104','47865T105'
);
