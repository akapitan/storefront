-- ════════════════════════════════════════════════════════════════════════════
-- V8__mcmaster_full_categories.sql
-- Full McMaster-Carr style category hierarchy: 26 top-level categories
-- with depth-1 subcategory groups and depth-2 leaf items.
-- Replaces the 4 seed categories from V6 with the complete set.
-- ════════════════════════════════════════════════════════════════════════════

-- Clean up existing V6 categories and their dependent data.
-- product_groups, attribute_definitions etc. have ON DELETE CASCADE or
-- reference categories; we clean them up explicitly to be safe.

-- Remove SKU-level data first (deepest dependencies)
DELETE FROM sku_price_tiers WHERE sku_id IN (
    SELECT s.id FROM skus s
    JOIN product_groups pg ON pg.id = s.product_group_id
    JOIN categories c ON c.id = pg.category_id
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);
DELETE FROM sku_attributes WHERE sku_id IN (
    SELECT s.id FROM skus s
    JOIN product_groups pg ON pg.id = s.product_group_id
    JOIN categories c ON c.id = pg.category_id
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);
DELETE FROM skus WHERE product_group_id IN (
    SELECT pg.id FROM product_groups pg
    JOIN categories c ON c.id = pg.category_id
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);
DELETE FROM product_group_columns WHERE product_group_id IN (
    SELECT pg.id FROM product_groups pg
    JOIN categories c ON c.id = pg.category_id
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);
DELETE FROM product_groups WHERE category_id IN (
    SELECT c.id FROM categories c
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);

-- Remove attribute options before attribute definitions
DELETE FROM attribute_options WHERE attribute_id IN (
    SELECT ad.id FROM attribute_definitions ad
    JOIN categories c ON c.id = ad.category_id
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);
DELETE FROM attribute_definitions WHERE category_id IN (
    SELECT c.id FROM categories c
    WHERE c.slug IN ('fastening','raw-materials','electrical','hand-tools')
       OR c.path <@ 'Fastening' OR c.path <@ 'RawMaterials'
       OR c.path <@ 'Electrical' OR c.path <@ 'HandTools'
);

-- Now remove categories in depth order
DELETE FROM categories WHERE depth = 2
    AND (path <@ 'Fastening' OR path <@ 'RawMaterials'
         OR path <@ 'Electrical' OR path <@ 'HandTools');
DELETE FROM categories WHERE depth = 1
    AND (path <@ 'Fastening' OR path <@ 'RawMaterials'
         OR path <@ 'Electrical' OR path <@ 'HandTools');
DELETE FROM categories WHERE depth = 0
    AND slug IN ('fastening','raw-materials','electrical','hand-tools');

-- ── 26 Top-Level Categories (depth 0) ─────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order) VALUES
(NULL, 'fastening-joining',    'Fastening & Joining',            'FasteningJoining',        0, FALSE, 1),
(NULL, 'raw-materials',        'Raw Materials',                  'RawMaterials',             0, FALSE, 2),
(NULL, 'plumbing',             'Plumbing',                       'Plumbing',                 0, FALSE, 3),
(NULL, 'electrical',           'Electrical',                     'Electrical',               0, FALSE, 4),
(NULL, 'hand-tools',           'Hand Tools',                     'HandTools',                0, FALSE, 5),
(NULL, 'power-transmission',   'Power Transmission',             'PowerTransmission',        0, FALSE, 6),
(NULL, 'hardware',             'Hardware',                       'Hardware',                 0, FALSE, 7),
(NULL, 'fluid-power',          'Fluid Power',                    'FluidPower',               0, FALSE, 8),
(NULL, 'material-handling',    'Material Handling',              'MaterialHandling',         0, FALSE, 9),
(NULL, 'machining',            'Machining',                      'Machining',                0, FALSE, 10),
(NULL, 'heating-cooling',      'Heating & Cooling',              'HeatingCooling',           0, FALSE, 11),
(NULL, 'rubber-plastic',       'Rubber & Plastic',               'RubberPlastic',            0, FALSE, 12),
(NULL, 'building-grounds',     'Building & Grounds',             'BuildingGrounds',          0, FALSE, 13),
(NULL, 'adhesives-sealants',   'Adhesives, Sealants & Tape',    'AdhesivesSealants',        0, FALSE, 14),
(NULL, 'safety-supplies',      'Safety Supplies',                'SafetySupplies',           0, FALSE, 15),
(NULL, 'measuring-inspecting', 'Measuring & Inspecting',         'MeasuringInspecting',      0, FALSE, 16),
(NULL, 'abrasives',            'Abrasives',                      'Abrasives',                0, FALSE, 17),
(NULL, 'painting',             'Painting',                       'Painting',                 0, FALSE, 18),
(NULL, 'filtration',           'Filtration',                     'Filtration',               0, FALSE, 19),
(NULL, 'office-furniture',     'Office Supplies & Furniture',    'OfficeFurniture',          0, FALSE, 20),
(NULL, 'welding',              'Welding',                        'Welding',                  0, FALSE, 21),
(NULL, 'pressure-vacuum',      'Pressure & Vacuum',              'PressureVacuum',           0, FALSE, 22),
(NULL, 'lubrication',          'Lubrication',                    'Lubrication',              0, FALSE, 23),
(NULL, 'test-equipment',       'Test & Measurement Equipment',   'TestEquipment',            0, FALSE, 24),
(NULL, 'motion-control',       'Motion Control',                 'MotionControl',            0, FALSE, 25),
(NULL, 'cleaning-janitorial',  'Cleaning & Janitorial',          'CleaningJanitorial',       0, FALSE, 26);

-- ══════════════════════════════════════════════════════════════════════════
-- DEPTH-1 subcategory groups (section headers) + DEPTH-2 leaf items
-- ══════════════════════════════════════════════════════════════════════════

-- ── 1. Fastening & Joining ────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('screws-bolts',     'Screws & Bolts',          'ScrewsBolts',        1),
    ('nuts',             'Nuts',                    'Nuts',               2),
    ('washers',          'Washers',                 'Washers',            3),
    ('rivets',           'Rivets',                  'Rivets',             4),
    ('anchors',          'Anchors',                 'Anchors',            5),
    ('pins-clips',       'Pins & Clips',            'PinsClips',          6),
    ('retaining-rings',  'Retaining Rings',         'RetainingRings',     7),
    ('threaded-inserts', 'Threaded Inserts',        'ThreadedInserts',    8)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'fastening-joining';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hex-head-cap-screws',    'Hex Head Cap Screws',    'HexHeadCapScrews',    1),
    ('socket-head-cap-screws', 'Socket Head Cap Screws', 'SocketHeadCapScrews', 2),
    ('machine-screws',         'Machine Screws',         'MachineScrews',       3),
    ('sheet-metal-screws',     'Sheet Metal Screws',     'SheetMetalScrews',    4),
    ('wood-screws',            'Wood Screws',            'WoodScrews',          5),
    ('carriage-bolts',         'Carriage Bolts',         'CarriageBolts',       6),
    ('shoulder-screws',        'Shoulder Screws',        'ShoulderScrews',      7),
    ('set-screws',             'Set Screws',             'SetScrews',           8),
    ('threaded-rods-studs',    'Threaded Rods & Studs',  'ThreadedRodsStuds',   9),
    ('u-bolts',                'U-Bolts',                'UBolts',              10),
    ('eye-bolts',              'Eye Bolts',              'EyeBolts',            11)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'screws-bolts';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hex-nuts',     'Hex Nuts',      'HexNuts',     1),
    ('lock-nuts',    'Lock Nuts',     'LockNuts',    2),
    ('flange-nuts',  'Flange Nuts',   'FlangeNuts',  3),
    ('wing-nuts',    'Wing Nuts',     'WingNuts',    4),
    ('cap-nuts',     'Cap Nuts',      'CapNuts',     5),
    ('coupling-nuts','Coupling Nuts', 'CouplingNuts',6),
    ('tee-nuts',     'Tee Nuts',      'TeeNuts',     7)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'nuts';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('flat-washers',  'Flat Washers',  'FlatWashers',  1),
    ('lock-washers',  'Lock Washers',  'LockWashers',  2),
    ('fender-washers','Fender Washers','FenderWashers', 3),
    ('spring-washers','Spring Washers','SpringWashers', 4),
    ('shim-washers',  'Shim Washers',  'ShimWashers',  5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'washers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('blind-rivets',     'Blind Rivets',      'BlindRivets',     1),
    ('solid-rivets',     'Solid Rivets',      'SolidRivets',     2),
    ('rivet-nuts',       'Rivet Nuts',        'RivetNuts',       3),
    ('drive-rivets',     'Drive Rivets',      'DriveRivets',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'rivets';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('wedge-anchors',      'Wedge Anchors',       'WedgeAnchors',       1),
    ('sleeve-anchors',     'Sleeve Anchors',      'SleeveAnchors',      2),
    ('drop-in-anchors',    'Drop-In Anchors',     'DropInAnchors',      3),
    ('toggle-bolts',       'Toggle Bolts',        'ToggleBolts',        4),
    ('concrete-screws',    'Concrete Screws',     'ConcreteScrews',     5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'anchors';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('dowel-pins',        'Dowel Pins',          'DowelPins',         1),
    ('cotter-pins',       'Cotter Pins',         'CotterPins',        2),
    ('spring-pins',       'Spring Pins',         'SpringPins',        3),
    ('clevis-pins',       'Clevis Pins',         'ClevisPins',        4),
    ('hair-pin-clips',    'Hair Pin Clips',      'HairPinClips',      5),
    ('r-clips',           'R-Clips',             'RClips',            6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pins-clips';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('internal-retaining-rings', 'Internal Retaining Rings', 'InternalRetainingRings', 1),
    ('external-retaining-rings', 'External Retaining Rings', 'ExternalRetainingRings', 2),
    ('e-clips',                  'E-Clips',                  'EClips',                 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'retaining-rings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('helical-inserts',   'Helical Inserts',    'HelicalInserts',   1),
    ('press-fit-inserts', 'Press-Fit Inserts',  'PressFitInserts',  2),
    ('key-locking-inserts','Key-Locking Inserts','KeyLockingInserts',3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'threaded-inserts';

-- ── 2. Raw Materials ──────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('steel',      'Steel',          'Steel',       1),
    ('aluminum',   'Aluminum',       'Aluminum',    2),
    ('stainless',  'Stainless Steel','Stainless',   3),
    ('brass-bronze','Brass & Bronze','BrassBronze', 4),
    ('plastics',   'Plastics',       'Plastics',    5),
    ('rubber',     'Rubber',         'Rubber',      6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'raw-materials';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('steel-sheets',    'Steel Sheets & Plates',  'SteelSheets',   1),
    ('steel-bars',      'Steel Bars & Rods',      'SteelBars',     2),
    ('steel-tubing',    'Steel Tubing',            'SteelTubing',   3),
    ('steel-angles',    'Steel Angles & Channels', 'SteelAngles',   4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'steel';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('aluminum-sheets','Aluminum Sheets & Plates','AluminumSheets', 1),
    ('aluminum-bars',  'Aluminum Bars & Rods',    'AluminumBars',   2),
    ('aluminum-tubing','Aluminum Tubing',          'AluminumTubing', 3),
    ('aluminum-angles','Aluminum Angles',          'AluminumAngles', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'aluminum';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('ss-sheets','Stainless Steel Sheets',  'SSSheets', 1),
    ('ss-bars',  'Stainless Steel Bars',    'SSBars',   2),
    ('ss-tubing','Stainless Steel Tubing',  'SSTubing', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'stainless';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('brass-bars',   'Brass Bars & Rods',    'BrassBars',   1),
    ('brass-sheets', 'Brass Sheets',         'BrassSheets', 2),
    ('bronze-bars',  'Bronze Bars & Rods',   'BronzeBars',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'brass-bronze';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('acetal-sheets',    'Acetal Sheets & Rods',     'AcetalSheets',   1),
    ('nylon-sheets',     'Nylon Sheets & Rods',      'NylonSheets',    2),
    ('polycarbonate',    'Polycarbonate Sheets',      'Polycarbonate',  3),
    ('hdpe-sheets',      'HDPE Sheets',               'HDPESheets',     4),
    ('ptfe-sheets',      'PTFE Sheets & Rods',        'PTFESheets',     5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'plastics';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('rubber-sheets',    'Rubber Sheets & Strips',  'RubberSheets',    1),
    ('rubber-cord',      'Rubber Cord & Tubing',    'RubberCord',      2),
    ('silicone-sheets',  'Silicone Sheets',         'SiliconeSheets',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'rubber';

-- ── 3. Plumbing ───────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('pipe-fittings',    'Pipe Fittings',          'PipeFittings',      1),
    ('valves',           'Valves',                 'Valves',            2),
    ('tubing-hose',      'Tubing & Hose',          'TubingHose',        3),
    ('pipe',             'Pipe',                   'Pipe',              4),
    ('tube-fittings',    'Tube Fittings',          'TubeFittings',      5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'plumbing';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('pipe-elbows',     'Pipe Elbows',       'PipeElbows',     1),
    ('pipe-tees',       'Pipe Tees',         'PipeTees',       2),
    ('pipe-couplings',  'Pipe Couplings',    'PipeCouplings',  3),
    ('pipe-nipples',    'Pipe Nipples',      'PipeNipples',    4),
    ('pipe-adapters',   'Pipe Adapters',     'PipeAdapters',   5),
    ('pipe-unions',     'Pipe Unions',       'PipeUnions',     6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pipe-fittings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('ball-valves',   'Ball Valves',    'BallValves',   1),
    ('gate-valves',   'Gate Valves',    'GateValves',   2),
    ('check-valves',  'Check Valves',   'CheckValves',  3),
    ('needle-valves', 'Needle Valves',  'NeedleValves', 4),
    ('solenoid-valves','Solenoid Valves','SolenoidValves',5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'valves';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('plastic-tubing',  'Plastic Tubing',    'PlasticTubing',  1),
    ('metal-tubing',    'Metal Tubing',      'MetalTubing',    2),
    ('rubber-hose',     'Rubber Hose',       'RubberHose',     3),
    ('silicone-tubing', 'Silicone Tubing',   'SiliconeTubing', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'tubing-hose';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('steel-pipe',    'Steel Pipe',      'SteelPipe',    1),
    ('pvc-pipe',      'PVC Pipe',        'PVCPipe',      2),
    ('copper-pipe',   'Copper Pipe',     'CopperPipe',   3),
    ('ss-pipe',       'Stainless Steel Pipe', 'SSPipe',  4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pipe';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('compression-fittings', 'Compression Fittings', 'CompressionFittings', 1),
    ('push-to-connect',      'Push-to-Connect Fittings', 'PushToConnect',   2),
    ('flare-fittings',       'Flare Fittings',       'FlareFittings',       3),
    ('barbed-fittings',      'Barbed Fittings',      'BarbedFittings',      4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'tube-fittings';

-- ── 4. Electrical ─────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('wire-cable',        'Wire & Cable',           'WireCable',         1),
    ('connectors',        'Connectors',             'Connectors',        2),
    ('switches-relays',   'Switches & Relays',      'SwitchesRelays',    3),
    ('conduit-raceways',  'Conduit & Raceways',     'ConduitRaceways',   4),
    ('terminal-blocks',   'Terminal Blocks',         'TerminalBlocks',    5),
    ('circuit-protection','Circuit Protection',      'CircuitProtection', 6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'electrical';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hookup-wire',     'Hookup Wire',           'HookupWire',     1),
    ('multiconductor',  'Multiconductor Cable',  'Multiconductor', 2),
    ('coaxial-cable',   'Coaxial Cable',         'CoaxialCable',   3),
    ('heat-shrink',     'Heat-Shrink Tubing',    'HeatShrink',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'wire-cable';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('crimp-connectors',  'Crimp Connectors',      'CrimpConnectors',  1),
    ('wire-terminals',    'Wire Terminals',         'WireTerminals',    2),
    ('circular-connectors','Circular Connectors',   'CircularConnectors',3),
    ('plug-receptacles',  'Plugs & Receptacles',   'PlugReceptacles',   4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'connectors';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('toggle-switches',  'Toggle Switches',    'ToggleSwitches',  1),
    ('rocker-switches',  'Rocker Switches',    'RockerSwitches',  2),
    ('push-switches',    'Pushbutton Switches','PushSwitches',    3),
    ('relays',           'Relays',             'Relays',          4),
    ('limit-switches',   'Limit Switches',     'LimitSwitches',   5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'switches-relays';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('rigid-conduit',     'Rigid Conduit',       'RigidConduit',     1),
    ('flexible-conduit',  'Flexible Conduit',    'FlexibleConduit',  2),
    ('wire-duct',         'Wire Duct',           'WireDuct',         3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'conduit-raceways';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('din-terminal-blocks', 'DIN-Rail Terminal Blocks', 'DINTerminalBlocks', 1),
    ('barrier-strips',      'Barrier Terminal Strips',  'BarrierStrips',     2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'terminal-blocks';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('fuses',             'Fuses',                'Fuses',            1),
    ('circuit-breakers',  'Circuit Breakers',     'CircuitBreakers',  2),
    ('surge-protectors',  'Surge Protectors',     'SurgeProtectors',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'circuit-protection';

-- ── 5. Hand Tools ─────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('wrenches',    'Wrenches',           'Wrenches',     1),
    ('pliers',      'Pliers',             'Pliers',       2),
    ('screwdrivers','Screwdrivers',       'Screwdrivers', 3),
    ('hex-keys',    'Hex Keys',           'HexKeys',      4),
    ('hammers',     'Hammers & Mallets',  'Hammers',      5),
    ('cutting-tools','Cutting Tools',     'CuttingTools',  6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hand-tools';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('combination-wrenches', 'Combination Wrenches',  'CombinationWrenches', 1),
    ('adjustable-wrenches',  'Adjustable Wrenches',   'AdjustableWrenches',  2),
    ('socket-wrenches',      'Socket Wrenches',       'SocketWrenches',      3),
    ('torque-wrenches',      'Torque Wrenches',       'TorqueWrenches',      4),
    ('pipe-wrenches',        'Pipe Wrenches',         'PipeWrenches',        5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'wrenches';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('needle-nose-pliers',  'Needle-Nose Pliers',   'NeedleNosePliers',   1),
    ('slip-joint-pliers',   'Slip-Joint Pliers',    'SlipJointPliers',    2),
    ('locking-pliers',      'Locking Pliers',       'LockingPliers',      3),
    ('diagonal-cutters',    'Diagonal Cutters',     'DiagonalCutters',    4),
    ('snap-ring-pliers',    'Snap Ring Pliers',     'SnapRingPliers',     5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pliers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('phillips-screwdrivers', 'Phillips Screwdrivers', 'PhillipsScrewdrivers', 1),
    ('flathead-screwdrivers', 'Flathead Screwdrivers', 'FlatheadScrewdrivers', 2),
    ('torx-screwdrivers',     'Torx Screwdrivers',     'TorxScrewdrivers',     3),
    ('precision-screwdrivers','Precision Screwdrivers', 'PrecisionScrewdrivers',4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'screwdrivers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('l-shape-hex-keys',   'L-Shape Hex Keys',      'LShapeHexKeys',    1),
    ('hex-bit-sockets',    'Hex Bit Sockets',       'HexBitSockets',    2),
    ('ball-end-hex-keys',  'Ball-End Hex Keys',     'BallEndHexKeys',   3),
    ('hex-key-sets',       'Hex Key Sets',          'HexKeySets',       4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hex-keys';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('ball-peen-hammers', 'Ball Peen Hammers',  'BallPeenHammers', 1),
    ('dead-blow-hammers', 'Dead-Blow Hammers',  'DeadBlowHammers', 2),
    ('rubber-mallets',    'Rubber Mallets',     'RubberMallets',    3),
    ('sledgehammers',     'Sledgehammers',      'Sledgehammers',    4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hammers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('utility-knives',    'Utility Knives',      'UtilityKnives',    1),
    ('snips',             'Snips & Shears',      'Snips',            2),
    ('hacksaws',          'Hacksaws',            'Hacksaws',         3),
    ('hole-punches',      'Hole Punches',        'HolePunches',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'cutting-tools';

-- ── 6. Power Transmission ─────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('bearings',      'Bearings',             'Bearings',        1),
    ('belts-pulleys', 'Belts & Pulleys',      'BeltsPulleys',    2),
    ('gears',         'Gears',                'Gears',           3),
    ('chains-sprockets','Chains & Sprockets', 'ChainsSprockets', 4),
    ('shafts',        'Shafts',               'Shafts',          5),
    ('couplings',     'Couplings',            'Couplings',       6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'power-transmission';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('ball-bearings',   'Ball Bearings',     'BallBearings',   1),
    ('roller-bearings', 'Roller Bearings',   'RollerBearings', 2),
    ('sleeve-bearings', 'Sleeve Bearings',   'SleeveBearings', 3),
    ('thrust-bearings', 'Thrust Bearings',   'ThrustBearings', 4),
    ('mounted-bearings','Mounted Bearings',  'MountedBearings',5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'bearings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('v-belts',         'V-Belts',           'VBelts',         1),
    ('timing-belts',    'Timing Belts',      'TimingBelts',    2),
    ('flat-belts',      'Flat Belts',        'FlatBelts',      3),
    ('v-belt-pulleys',  'V-Belt Pulleys',    'VBeltPulleys',   4),
    ('timing-pulleys',  'Timing Pulleys',    'TimingPulleys',  5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'belts-pulleys';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('spur-gears',    'Spur Gears',     'SpurGears',    1),
    ('bevel-gears',   'Bevel Gears',    'BevelGears',   2),
    ('worm-gears',    'Worm Gears',     'WormGears',    3),
    ('gear-racks',    'Gear Racks',     'GearRacks',    4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'gears';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('roller-chains',   'Roller Chains',   'RollerChains',   1),
    ('chain-sprockets', 'Chain Sprockets', 'ChainSprockets', 2),
    ('chain-links',     'Chain Links',     'ChainLinks',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'chains-sprockets';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('solid-shafts',    'Solid Shafts',      'SolidShafts',    1),
    ('hollow-shafts',   'Hollow Shafts',     'HollowShafts',   2),
    ('keyed-shafts',    'Keyed Shafts',      'KeyedShafts',    3),
    ('shaft-collars',   'Shaft Collars',     'ShaftCollars',   4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'shafts';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('jaw-couplings',    'Jaw Couplings',     'JawCouplings',    1),
    ('flexible-couplings','Flexible Couplings','FlexibleCouplings',2),
    ('rigid-couplings',  'Rigid Couplings',   'RigidCouplings',  3),
    ('universal-joints', 'Universal Joints',  'UniversalJoints', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'couplings';

-- ── 7. Hardware ───────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('hinges',          'Hinges',                 'Hinges',         1),
    ('latches-locks',   'Latches & Locks',        'LatchesLocks',   2),
    ('handles-knobs',   'Handles & Knobs',        'HandlesKnobs',   3),
    ('springs',         'Springs',                'Springs',        4),
    ('magnets',         'Magnets',                'Magnets',        5),
    ('leveling-feet',   'Leveling Feet & Casters','LevelingFeet',   6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hardware';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('butt-hinges',       'Butt Hinges',         'ButtHinges',       1),
    ('piano-hinges',      'Piano Hinges',        'PianoHinges',      2),
    ('spring-hinges',     'Spring Hinges',       'SpringHinges',     3),
    ('concealed-hinges',  'Concealed Hinges',    'ConcealedHinges',  4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hinges';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('draw-latches',    'Draw Latches',      'DrawLatches',    1),
    ('cam-locks',       'Cam Locks',         'CamLocks',       2),
    ('padlocks',        'Padlocks',          'Padlocks',       3),
    ('slide-bolts',     'Slide Bolts',       'SlideBolts',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'latches-locks';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('pull-handles',    'Pull Handles',      'PullHandles',    1),
    ('t-handles',       'T-Handles',         'THandles',       2),
    ('knobs',           'Knobs',             'Knobs',          3),
    ('handwheels',      'Handwheels',        'Handwheels',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'handles-knobs';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('compression-springs', 'Compression Springs', 'CompressionSprings', 1),
    ('extension-springs',   'Extension Springs',   'ExtensionSprings',   2),
    ('torsion-springs',     'Torsion Springs',     'TorsionSprings',     3),
    ('die-springs',         'Die Springs',         'DieSprings',         4),
    ('gas-springs',         'Gas Springs',         'GasSprings',         5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'springs';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('neodymium-magnets', 'Neodymium Magnets',   'NeodymiumMagnets', 1),
    ('ceramic-magnets',   'Ceramic Magnets',     'CeramicMagnets',   2),
    ('magnetic-strips',   'Magnetic Strips',     'MagneticStrips',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'magnets';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('leveling-mounts',    'Leveling Mounts',     'LevelingMounts',    1),
    ('swivel-casters',     'Swivel Casters',      'SwivelCasters',     2),
    ('rigid-casters',      'Rigid Casters',       'RigidCasters',      3),
    ('furniture-glides',   'Furniture Glides',    'FurnitureGlides',   4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'leveling-feet';

-- ── 8. Fluid Power ───────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('hydraulic-cylinders',   'Hydraulic Cylinders',    'HydraulicCylinders',   1),
    ('pneumatic-cylinders',   'Pneumatic Cylinders',    'PneumaticCylinders',   2),
    ('hydraulic-fittings',    'Hydraulic Fittings',     'HydraulicFittings',    3),
    ('pneumatic-fittings',    'Pneumatic Fittings',     'PneumaticFittings',    4),
    ('air-compressors',       'Air Compressors',        'AirCompressors',       5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'fluid-power';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('single-acting-hyd',  'Single-Acting Hydraulic Cylinders', 'SingleActingHyd',  1),
    ('double-acting-hyd',  'Double-Acting Hydraulic Cylinders', 'DoubleActingHyd',  2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hydraulic-cylinders';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('single-acting-pneu', 'Single-Acting Pneumatic Cylinders', 'SingleActingPneu', 1),
    ('double-acting-pneu', 'Double-Acting Pneumatic Cylinders', 'DoubleActingPneu', 2),
    ('compact-cylinders',  'Compact Pneumatic Cylinders',       'CompactCylinders', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pneumatic-cylinders';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hydraulic-adapters',  'Hydraulic Adapters',   'HydraulicAdapters',  1),
    ('hydraulic-couplings', 'Hydraulic Couplings',  'HydraulicCouplings', 2),
    ('hydraulic-hose',      'Hydraulic Hose',       'HydraulicHose',      3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hydraulic-fittings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('push-in-fittings',   'Push-In Fittings',     'PushInFittings',    1),
    ('barb-fittings-pneu', 'Barb Fittings',        'BarbFittingsPneu',  2),
    ('quick-connects',     'Quick-Connect Fittings','QuickConnects',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pneumatic-fittings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('portable-compressors',   'Portable Compressors',    'PortableCompressors',   1),
    ('stationary-compressors', 'Stationary Compressors',  'StationaryCompressors', 2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'air-compressors';

-- ── 9. Material Handling ──────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('carts-trucks',    'Carts & Trucks',        'CartsTrucks',    1),
    ('hoists-cranes',   'Hoists & Cranes',       'HoistsCranes',   2),
    ('shelving-storage','Shelving & Storage',     'ShelvingStorage', 3),
    ('conveyors',       'Conveyors',             'Conveyors',       4),
    ('lifting-hardware','Lifting Hardware',       'LiftingHardware', 5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'material-handling';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('platform-trucks',  'Platform Trucks',   'PlatformTrucks',  1),
    ('hand-trucks',      'Hand Trucks',       'HandTrucks',      2),
    ('utility-carts',    'Utility Carts',     'UtilityCarts',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'carts-trucks';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('chain-hoists',     'Chain Hoists',      'ChainHoists',     1),
    ('electric-hoists',  'Electric Hoists',   'ElectricHoists',  2),
    ('jib-cranes',       'Jib Cranes',        'JibCranes',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hoists-cranes';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('wire-shelving',    'Wire Shelving',     'WireShelving',    1),
    ('steel-shelving',   'Steel Shelving',    'SteelShelving',   2),
    ('storage-bins',     'Storage Bins',      'StorageBins',     3),
    ('lockers',          'Lockers',           'Lockers',         4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'shelving-storage';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('roller-conveyors',  'Roller Conveyors',   'RollerConveyors',  1),
    ('belt-conveyors',    'Belt Conveyors',     'BeltConveyors',    2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'conveyors';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('eye-hooks',        'Eye Hooks',          'EyeHooks',        1),
    ('shackles',         'Shackles',           'Shackles',        2),
    ('turnbuckles',      'Turnbuckles',        'Turnbuckles',     3),
    ('wire-rope',        'Wire Rope',          'WireRope',        4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'lifting-hardware';

-- ── 10. Machining ─────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('drills-taps',       'Drills & Taps',          'DrillsTaps',       1),
    ('end-mills',         'End Mills',              'EndMills',         2),
    ('inserts',           'Cutting Inserts',        'Inserts',          3),
    ('reamers',           'Reamers',                'Reamers',          4),
    ('saw-blades',        'Saw Blades',             'SawBlades',        5),
    ('workholding',       'Workholding',            'Workholding',      6)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'machining';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('twist-drills',     'Twist Drill Bits',    'TwistDrills',     1),
    ('step-drills',      'Step Drill Bits',     'StepDrills',      2),
    ('hand-taps',        'Hand Taps',           'HandTaps',        3),
    ('spiral-taps',      'Spiral Flute Taps',   'SpiralTaps',      4),
    ('thread-dies',      'Thread Dies',         'ThreadDies',      5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'drills-taps';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('square-end-mills',   'Square End Mills',    'SquareEndMills',   1),
    ('ball-end-mills',     'Ball End Mills',      'BallEndMills',     2),
    ('roughing-end-mills', 'Roughing End Mills',  'RoughingEndMills', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'end-mills';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('turning-inserts',  'Turning Inserts',   'TurningInserts',  1),
    ('milling-inserts',  'Milling Inserts',   'MillingInserts',  2),
    ('threading-inserts','Threading Inserts', 'ThreadingInserts', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'inserts';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hand-reamers',      'Hand Reamers',       'HandReamers',      1),
    ('chucking-reamers',  'Chucking Reamers',   'ChuckingReamers',  2),
    ('adjustable-reamers','Adjustable Reamers', 'AdjustableReamers', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'reamers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('circular-saw-blades',  'Circular Saw Blades',   'CircularSawBlades',  1),
    ('band-saw-blades',      'Band Saw Blades',       'BandSawBlades',      2),
    ('jigsaw-blades',        'Jigsaw Blades',         'JigsawBlades',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'saw-blades';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('vises',            'Vises',              'Vises',            1),
    ('clamps',           'Clamps',             'Clamps',           2),
    ('chucks',           'Chucks',             'Chucks',           3),
    ('collets',          'Collets',            'Collets',          4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'workholding';

-- ── 11. Heating & Cooling ─────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('heaters',     'Heaters',          'Heaters',     1),
    ('fans-blowers','Fans & Blowers',   'FansBlowers', 2),
    ('heat-exchangers','Heat Exchangers','HeatExchangers',3),
    ('thermostats', 'Thermostats',      'Thermostats', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'heating-cooling';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('cartridge-heaters', 'Cartridge Heaters',  'CartridgeHeaters', 1),
    ('band-heaters',      'Band Heaters',       'BandHeaters',      2),
    ('strip-heaters',     'Strip Heaters',      'StripHeaters',     3),
    ('immersion-heaters', 'Immersion Heaters',  'ImmersionHeaters', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'heaters';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('axial-fans',       'Axial Fans',          'AxialFans',       1),
    ('centrifugal-fans', 'Centrifugal Fans',    'CentrifugalFans', 2),
    ('blowers',          'Blowers',             'Blowers',         3),
    ('exhaust-fans',     'Exhaust Fans',        'ExhaustFans',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'fans-blowers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('plate-heat-exchangers', 'Plate Heat Exchangers', 'PlateHeatExchangers', 1),
    ('shell-tube-exchangers', 'Shell & Tube Exchangers','ShellTubeExchangers', 2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'heat-exchangers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('mechanical-thermostats', 'Mechanical Thermostats', 'MechanicalThermostats', 1),
    ('digital-thermostats',    'Digital Thermostats',    'DigitalThermostats',    2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'thermostats';

-- ── 12. Rubber & Plastic ──────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('o-rings-seals',    'O-Rings & Seals',       'ORingsSeals',     1),
    ('gaskets',          'Gaskets',               'Gaskets',         2),
    ('plastic-fittings', 'Plastic Fittings',      'PlasticFittings', 3),
    ('bumpers-grommets', 'Bumpers & Grommets',    'BumpersGrommets', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'rubber-plastic';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('buna-n-o-rings',    'Buna-N O-Rings',      'BunaNORings',    1),
    ('silicone-o-rings',  'Silicone O-Rings',    'SiliconeORings', 2),
    ('viton-o-rings',     'Viton O-Rings',       'VitonORings',    3),
    ('oil-seals',         'Oil Seals',           'OilSeals',       4),
    ('o-ring-kits',       'O-Ring Kits',         'ORingKits',      5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'o-rings-seals';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('sheet-gaskets',    'Sheet Gaskets',       'SheetGaskets',    1),
    ('flange-gaskets',   'Flange Gaskets',      'FlangeGaskets',   2),
    ('gasket-cord',      'Gasket Cord & Strip', 'GasketCord',      3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'gaskets';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('nylon-fittings',   'Nylon Fittings',      'NylonFittings',   1),
    ('pvc-fittings',     'PVC Fittings',        'PVCFittings',     2),
    ('polypro-fittings', 'Polypropylene Fittings','PolyproFittings',3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'plastic-fittings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('rubber-bumpers',    'Rubber Bumpers',     'RubberBumpers',    1),
    ('rubber-grommets',   'Rubber Grommets',    'RubberGrommets',   2),
    ('vibration-dampers', 'Vibration Dampers',  'VibrationDampers', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'bumpers-grommets';

-- ── 13. Building & Grounds ────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('doors-access',     'Doors & Access Control', 'DoorsAccess',    1),
    ('flooring',         'Flooring',               'Flooring',       2),
    ('signs-labels',     'Signs & Labels',         'SignsLabels',    3),
    ('outdoor-grounds',  'Outdoor & Grounds',      'OutdoorGrounds', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'building-grounds';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('door-closers',    'Door Closers',      'DoorClosers',    1),
    ('door-hardware',   'Door Hardware',     'DoorHardware',   2),
    ('access-panels',   'Access Panels',     'AccessPanels',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'doors-access';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('anti-fatigue-mats',  'Anti-Fatigue Mats',   'AntiFatigueMats',  1),
    ('floor-tape',         'Floor Marking Tape',  'FloorTape',        2),
    ('floor-mats',         'Floor Mats',          'FloorMats',        3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'flooring';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('safety-signs',    'Safety Signs',       'SafetySigns',    1),
    ('pipe-markers',    'Pipe Markers',       'PipeMarkers',    2),
    ('label-printers',  'Label Printers',     'LabelPrinters',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'signs-labels';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('bollards',        'Bollards',            'Bollards',        1),
    ('speed-bumps',     'Speed Bumps',         'SpeedBumps',      2),
    ('parking-blocks',  'Parking Blocks',      'ParkingBlocks',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'outdoor-grounds';

-- ── 14. Adhesives, Sealants & Tape ────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('adhesives',    'Adhesives',        'Adhesives',    1),
    ('sealants',     'Sealants',         'Sealants',     2),
    ('tapes',        'Tapes',            'Tapes',        3),
    ('thread-sealants','Thread Sealants','ThreadSealants',4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'adhesives-sealants';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('epoxy-adhesives',     'Epoxy Adhesives',       'EpoxyAdhesives',     1),
    ('instant-adhesives',   'Instant Adhesives',     'InstantAdhesives',   2),
    ('structural-adhesives','Structural Adhesives',  'StructuralAdhesives',3),
    ('hot-melt-adhesives',  'Hot Melt Adhesives',    'HotMeltAdhesives',   4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'adhesives';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('silicone-sealants', 'Silicone Sealants',   'SiliconeSealants', 1),
    ('urethane-sealants', 'Urethane Sealants',   'UrethaneSealants', 2),
    ('pipe-sealants',     'Pipe Sealants',       'PipeSealants',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'sealants';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('duct-tape',         'Duct Tape',          'DuctTape',         1),
    ('electrical-tape',   'Electrical Tape',    'ElectricalTape',   2),
    ('masking-tape',      'Masking Tape',       'MaskingTape',      3),
    ('packaging-tape',    'Packaging Tape',     'PackagingTape',    4),
    ('double-sided-tape', 'Double-Sided Tape',  'DoubleSidedTape',  5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'tapes';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('ptfe-tape',          'PTFE Tape',            'PTFETape',          1),
    ('thread-locker',      'Thread Locker',        'ThreadLocker',      2),
    ('pipe-thread-sealant','Pipe Thread Sealant',  'PipeThreadSealant', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'thread-sealants';

-- ── 15. Safety Supplies ───────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('eye-protection',    'Eye Protection',       'EyeProtection',    1),
    ('hand-protection',   'Hand Protection',      'HandProtection',   2),
    ('hearing-protection','Hearing Protection',   'HearingProtection',3),
    ('respiratory',       'Respiratory Protection','Respiratory',      4),
    ('fall-protection',   'Fall Protection',       'FallProtection',   5)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'safety-supplies';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('safety-glasses',  'Safety Glasses',    'SafetyGlasses',  1),
    ('safety-goggles',  'Safety Goggles',    'SafetyGoggles',  2),
    ('face-shields',    'Face Shields',      'FaceShields',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'eye-protection';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('work-gloves',       'Work Gloves',        'WorkGloves',       1),
    ('disposable-gloves', 'Disposable Gloves',  'DisposableGloves', 2),
    ('chemical-gloves',   'Chemical-Resistant Gloves','ChemicalGloves',3),
    ('cut-resistant-gloves','Cut-Resistant Gloves','CutResistantGloves',4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hand-protection';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('earplugs',     'Earplugs',      'Earplugs',     1),
    ('earmuffs',     'Earmuffs',      'Earmuffs',     2),
    ('ear-bands',    'Ear Bands',     'EarBands',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'hearing-protection';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('dust-masks',         'Dust Masks',            'DustMasks',         1),
    ('half-face-respirators','Half-Face Respirators','HalfFaceRespirators',2),
    ('full-face-respirators','Full-Face Respirators','FullFaceRespirators',3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'respiratory';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('harnesses',     'Harnesses',      'Harnesses',     1),
    ('lanyards',      'Lanyards',       'Lanyards',      2),
    ('anchors-fall',  'Fall Anchors',   'AnchorsFall',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'fall-protection';

-- ── 16. Measuring & Inspecting ────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('calipers-micrometers', 'Calipers & Micrometers','CalipersMicrometers',1),
    ('gauges',               'Gauges',                'Gauges',              2),
    ('levels-squares',       'Levels & Squares',      'LevelsSquares',       3),
    ('tape-measures-rules',  'Tape Measures & Rules', 'TapeMeasuresRules',   4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'measuring-inspecting';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('digital-calipers',  'Digital Calipers',    'DigitalCalipers',  1),
    ('dial-calipers',     'Dial Calipers',       'DialCalipers',     2),
    ('outside-micrometers','Outside Micrometers','OutsideMicrometers',3),
    ('inside-micrometers', 'Inside Micrometers', 'InsideMicrometers', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'calipers-micrometers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('thread-gauges',   'Thread Gauges',     'ThreadGauges',   1),
    ('pin-gauges',      'Pin Gauges',        'PinGauges',      2),
    ('feeler-gauges',   'Feeler Gauges',     'FeelerGauges',   3),
    ('bore-gauges',     'Bore Gauges',       'BoreGauges',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'gauges';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('spirit-levels',     'Spirit Levels',      'SpiritLevels',     1),
    ('combination-squares','Combination Squares','CombinationSquares',2),
    ('protractors',       'Protractors',        'Protractors',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'levels-squares';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('tape-measures',   'Tape Measures',    'TapeMeasures',   1),
    ('steel-rules',     'Steel Rules',      'SteelRules',     2),
    ('folding-rules',   'Folding Rules',    'FoldingRules',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'tape-measures-rules';

-- ── 17. Abrasives ─────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('grinding-wheels',  'Grinding Wheels',     'GrindingWheels',  1),
    ('sanding-discs',    'Sanding Discs',       'SandingDiscs',    2),
    ('sandpaper',        'Sandpaper',           'Sandpaper',       3),
    ('deburring',        'Deburring Tools',     'Deburring',       4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'abrasives';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('bench-grinding-wheels', 'Bench Grinding Wheels',  'BenchGrindingWheels', 1),
    ('cutoff-wheels',         'Cutoff Wheels',          'CutoffWheels',        2),
    ('flap-discs',            'Flap Discs',             'FlapDiscs',           3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'grinding-wheels';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('hook-loop-discs',   'Hook & Loop Discs',  'HookLoopDiscs',   1),
    ('psa-discs',         'PSA Discs',          'PSADiscs',         2),
    ('fiber-discs',       'Fiber Discs',        'FiberDiscs',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'sanding-discs';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('sandpaper-sheets',  'Sandpaper Sheets',   'SandpaperSheets',  1),
    ('sandpaper-rolls',   'Sandpaper Rolls',    'SandpaperRolls',   2),
    ('sanding-belts',     'Sanding Belts',      'SandingBelts',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'sandpaper';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('deburring-blades',    'Deburring Blades',     'DeburringBlades',    1),
    ('deburring-wheels',    'Deburring Wheels',     'DeburringWheels',    2),
    ('deburring-tools-hand','Hand Deburring Tools', 'DeburringToolsHand', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'deburring';

-- ── 18. Painting ──────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('spray-paints',  'Spray Paints',        'SprayPaints',  1),
    ('brushes-rollers','Brushes & Rollers',  'BrushesRollers',2),
    ('paint-supplies', 'Paint Supplies',     'PaintSupplies', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'painting';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('enamel-spray-paint',  'Enamel Spray Paint',   'EnamelSprayPaint',  1),
    ('primer-spray',        'Primer Spray',         'PrimerSpray',       2),
    ('marking-paint',       'Marking Paint',        'MarkingPaint',      3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'spray-paints';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('paint-brushes',  'Paint Brushes',   'PaintBrushes',  1),
    ('paint-rollers',  'Paint Rollers',   'PaintRollers',  2),
    ('foam-brushes',   'Foam Brushes',    'FoamBrushes',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'brushes-rollers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('drop-cloths',    'Drop Cloths',      'DropCloths',    1),
    ('paint-trays',    'Paint Trays',      'PaintTrays',    2),
    ('painters-tape',  'Painters Tape',    'PaintersTape',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'paint-supplies';

-- ── 19. Filtration ────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('air-filters',    'Air Filters',       'AirFilters',    1),
    ('liquid-filters', 'Liquid Filters',    'LiquidFilters', 2),
    ('strainers',      'Strainers',         'Strainers',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'filtration';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('panel-air-filters',  'Panel Air Filters',    'PanelAirFilters',  1),
    ('pleated-filters',    'Pleated Filters',      'PleatedFilters',   2),
    ('hepa-filters',       'HEPA Filters',         'HEPAFilters',      3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'air-filters';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('cartridge-filters', 'Cartridge Filters',  'CartridgeFilters', 1),
    ('bag-filters',       'Bag Filters',        'BagFilters',       2),
    ('inline-filters',    'Inline Filters',     'InlineFilters',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'liquid-filters';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('y-strainers',       'Y-Strainers',        'YStrainers',       1),
    ('basket-strainers',  'Basket Strainers',   'BasketStrainers',  2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'strainers';

-- ── 20. Office Supplies & Furniture ───────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('desks-tables',    'Desks & Tables',     'DesksTables',    1),
    ('chairs',          'Chairs',             'Chairs',         2),
    ('storage-cabinets','Storage Cabinets',   'StorageCabinets',3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'office-furniture';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('workbenches',      'Workbenches',       'Workbenches',      1),
    ('computer-desks',   'Computer Desks',    'ComputerDesks',    2),
    ('folding-tables',   'Folding Tables',    'FoldingTables',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'desks-tables';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('office-chairs',    'Office Chairs',     'OfficeChairs',    1),
    ('shop-stools',      'Shop Stools',       'ShopStools',      2),
    ('drafting-chairs',  'Drafting Chairs',   'DraftingChairs',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'chairs';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('tool-cabinets',    'Tool Cabinets',     'ToolCabinets',    1),
    ('flammable-cabinets','Flammable Storage Cabinets','FlammableCabinets',2),
    ('file-cabinets',    'File Cabinets',     'FileCabinets',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'storage-cabinets';

-- ── 21. Welding ───────────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('welding-wire-rods', 'Welding Wire & Rods', 'WeldingWireRods', 1),
    ('welding-equipment', 'Welding Equipment',   'WeldingEquipment',2),
    ('welding-safety',    'Welding Safety',      'WeldingSafety',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'welding';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('mig-wire',       'MIG Wire',        'MIGWire',       1),
    ('tig-rods',       'TIG Rods',        'TIGRods',       2),
    ('stick-electrodes','Stick Electrodes','StickElectrodes',3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'welding-wire-rods';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('welding-clamps',   'Welding Clamps',    'WeldingClamps',   1),
    ('welding-magnets',  'Welding Magnets',   'WeldingMagnets',  2),
    ('welding-tables',   'Welding Tables',    'WeldingTables',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'welding-equipment';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('welding-helmets',  'Welding Helmets',   'WeldingHelmets',  1),
    ('welding-gloves',   'Welding Gloves',    'WeldingGloves',   2),
    ('welding-curtains', 'Welding Curtains',  'WeldingCurtains', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'welding-safety';

-- ── 22. Pressure & Vacuum ─────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('pressure-gauges',   'Pressure Gauges',     'PressureGauges',   1),
    ('regulators',        'Regulators',          'Regulators',       2),
    ('vacuum-pumps',      'Vacuum Pumps',        'VacuumPumps',      3),
    ('pressure-switches', 'Pressure Switches',   'PressureSwitches', 4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pressure-vacuum';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('analog-pressure-gauges', 'Analog Pressure Gauges','AnalogPressureGauges',1),
    ('digital-pressure-gauges','Digital Pressure Gauges','DigitalPressureGauges',2),
    ('vacuum-gauges',          'Vacuum Gauges',          'VacuumGauges',         3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pressure-gauges';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('pressure-regulators', 'Pressure Regulators',  'PressureRegulators', 1),
    ('vacuum-regulators',   'Vacuum Regulators',    'VacuumRegulators',   2),
    ('filter-regulators',   'Filter-Regulators',    'FilterRegulators',   3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'regulators';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('rotary-vane-pumps',   'Rotary Vane Pumps',   'RotaryVanePumps',   1),
    ('diaphragm-pumps-vac', 'Diaphragm Pumps',    'DiaphragmPumpsVac', 2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'vacuum-pumps';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('mechanical-pressure-switches', 'Mechanical Pressure Switches','MechanicalPressureSwitches',1),
    ('electronic-pressure-switches', 'Electronic Pressure Switches','ElectronicPressureSwitches',2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'pressure-switches';

-- ── 23. Lubrication ───────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('greases',       'Greases',         'Greases',       1),
    ('oils',          'Oils',            'Oils',          2),
    ('dry-lubricants','Dry Lubricants',  'DryLubricants', 3),
    ('grease-fittings','Grease Fittings','GreaseFittings',4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'lubrication';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('multipurpose-grease','Multipurpose Grease','MultipurposeGrease',1),
    ('high-temp-grease',   'High-Temp Grease',   'HighTempGrease',   2),
    ('food-grade-grease',  'Food-Grade Grease',  'FoodGradeGrease',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'greases';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('machine-oils',    'Machine Oils',      'MachineOils',    1),
    ('cutting-oils',    'Cutting Oils',      'CuttingOils',    2),
    ('penetrating-oils','Penetrating Oils',  'PenetratingOils',3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'oils';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('ptfe-lubricants', 'PTFE Lubricants',   'PTFELubricants', 1),
    ('graphite-lube',   'Graphite Lubricants','GraphiteLube',   2),
    ('moly-lube',       'Moly Lubricants',    'MolyLube',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'dry-lubricants';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('straight-grease-fittings', 'Straight Grease Fittings','StraightGreaseFittings',1),
    ('angled-grease-fittings',   'Angled Grease Fittings',  'AngledGreaseFittings',  2),
    ('grease-guns',              'Grease Guns',             'GreaseGuns',             3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'grease-fittings';

-- ── 24. Test & Measurement Equipment ──────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('multimeters',      'Multimeters',         'Multimeters',      1),
    ('thermometers',     'Thermometers',        'Thermometers',     2),
    ('flow-meters',      'Flow Meters',         'FlowMeters',       3),
    ('force-gauges',     'Force Gauges',        'ForceGauges',      4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'test-equipment';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('digital-multimeters', 'Digital Multimeters',  'DigitalMultimeters', 1),
    ('clamp-meters',        'Clamp Meters',         'ClampMeters',        2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'multimeters';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('infrared-thermometers', 'Infrared Thermometers',  'InfraredThermometers', 1),
    ('thermocouple-probes',   'Thermocouple Probes',    'ThermocoupleProbes',   2),
    ('bimetal-thermometers',  'Bimetal Thermometers',   'BimetalThermometers',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'thermometers';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('turbine-flow-meters',     'Turbine Flow Meters',      'TurbineFlowMeters',     1),
    ('variable-area-flow-meters','Variable-Area Flow Meters','VariableAreaFlowMeters',2),
    ('ultrasonic-flow-meters',  'Ultrasonic Flow Meters',   'UltrasonicFlowMeters',  3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'flow-meters';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('digital-force-gauges', 'Digital Force Gauges','DigitalForceGauges',1),
    ('spring-scales',        'Spring Scales',       'SpringScales',      2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'force-gauges';

-- ── 25. Motion Control ────────────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('linear-bearings',   'Linear Bearings & Guides','LinearBearings',   1),
    ('linear-actuators',  'Linear Actuators',        'LinearActuators',  2),
    ('lead-screws',       'Lead Screws & Ball Screws','LeadScrews',      3),
    ('motors',            'Motors',                   'Motors',           4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'motion-control';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('linear-ball-bearings',  'Linear Ball Bearings',  'LinearBallBearings',  1),
    ('linear-guide-rails',    'Linear Guide Rails',    'LinearGuideRails',    2),
    ('linear-slides',         'Linear Slides',         'LinearSlides',        3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'linear-bearings';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('electric-linear-actuators',  'Electric Linear Actuators', 'ElectricLinearActuators', 1),
    ('pneumatic-linear-actuators', 'Pneumatic Linear Actuators','PneumaticLinearActuators',2)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'linear-actuators';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('acme-lead-screws',   'Acme Lead Screws',   'AcmeLeadScrews',   1),
    ('ball-screws',        'Ball Screws',         'BallScrews',        2),
    ('lead-screw-nuts',    'Lead Screw Nuts',     'LeadScrewNuts',     3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'lead-screws';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('dc-motors',      'DC Motors',       'DCMotors',      1),
    ('stepper-motors', 'Stepper Motors',  'StepperMotors', 2),
    ('gear-motors',    'Gear Motors',     'GearMotors',    3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'motors';

-- ── 26. Cleaning & Janitorial ─────────────────────────────────────────────

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 1, FALSE, v.ord
FROM categories c, (VALUES
    ('cleaners',       'Cleaners & Degreasers',  'Cleaners',       1),
    ('wipers-rags',    'Wipers & Rags',           'WipersRags',     2),
    ('trash-recycling','Trash & Recycling',        'TrashRecycling', 3),
    ('brooms-mops',    'Brooms & Mops',            'BroomsMops',     4)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'cleaning-janitorial';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('all-purpose-cleaners', 'All-Purpose Cleaners',  'AllPurposeCleaners', 1),
    ('degreasers',           'Degreasers',            'Degreasers',         2),
    ('parts-washers',        'Parts Washers',         'PartsWashers',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'cleaners';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('shop-towels',      'Shop Towels',       'ShopTowels',      1),
    ('disposable-wipers','Disposable Wipers', 'DisposableWipers',2),
    ('cotton-rags',      'Cotton Rags',       'CottonRags',      3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'wipers-rags';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('trash-cans',     'Trash Cans',       'TrashCans',     1),
    ('trash-bags',     'Trash Bags',       'TrashBags',     2),
    ('recycling-bins', 'Recycling Bins',   'RecyclingBins', 3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'trash-recycling';

INSERT INTO categories (parent_id, slug, name, path, depth, is_leaf, sort_order)
SELECT c.id, v.slug, v.name, c.path || v.lpath, 2, TRUE, v.ord
FROM categories c, (VALUES
    ('push-brooms',    'Push Brooms',     'PushBrooms',    1),
    ('dust-mops',      'Dust Mops',       'DustMops',      2),
    ('wet-mops',       'Wet Mops',        'WetMops',       3)
) AS v(slug, name, lpath, ord)
WHERE c.slug = 'brooms-mops';
