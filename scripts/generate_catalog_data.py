#!/usr/bin/env python3
"""
Generate catalog seed data for the storefront application.

Produces SQL that populates leaf categories with attribute definitions,
product groups, SKUs, SKU attributes, and price tiers.

Usage:
    python3 scripts/generate_catalog_data.py | docker exec -i storefront-db psql -U storefront -d storefront_dev

Or save first, then run:
    python3 scripts/generate_catalog_data.py > /tmp/seed.sql
    docker exec -i storefront-db psql -U storefront -d storefront_dev < /tmp/seed.sql
"""

import uuid
import itertools
import sys
import math

# ════════════════════════════════════════════════════════════════════════════
# SQL helpers
# ════════════════════════════════════════════════════════════════════════════

def esc(s):
    """Escape single quotes for SQL."""
    return str(s).replace("'", "''")

def gen_uuid():
    return str(uuid.uuid4())

def sql_val(v):
    """Format a Python value as a SQL literal."""
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)):
        return str(v)
    return f"'{esc(v)}'"


# ════════════════════════════════════════════════════════════════════════════
# Category data definitions
# ════════════════════════════════════════════════════════════════════════════
#
# Each entry defines ONE leaf category and everything to populate it.
#
# Structure:
#   slug:           leaf category slug (must match V8 categories table)
#   material_from:  slug of the ancestor category where 'material' attr lives
#                   (None if this domain doesn't use a shared material attr)
#   attrs:          list of attribute definitions for this leaf
#   groups:         list of product groups, each with SKU variant data

CATEGORIES = []

def attr(key, label, dtype="enum", widget="checkbox", filterable=True,
         table_col=True, unit=None, tooltip=None, options=None):
    """Helper to define an attribute."""
    return {
        "key": key, "label": label, "data_type": dtype, "widget": widget,
        "filterable": filterable, "table_col": table_col,
        "unit": unit, "tooltip": tooltip,
        "options": options or [],
    }

def group(name, subtitle, slug, description, sort_primary,
          sort_secondary=None, uniform=None,
          varying_enum=None, varying_num=None,
          part_prefix="10000A", base_price=0.10, weight_base=0.01,
          sell_unit="Each", sell_qty=1, engineering_note=None):
    """Helper to define a product group with its SKU matrix."""
    return {
        "name": name, "subtitle": subtitle, "slug": slug,
        "description": description, "engineering_note": engineering_note,
        "sort_primary": sort_primary, "sort_secondary": sort_secondary,
        "uniform": uniform or {},
        "varying_enum": varying_enum or {},
        "varying_num": varying_num or {},
        "part_prefix": part_prefix, "base_price": base_price,
        "weight_base": weight_base, "sell_unit": sell_unit, "sell_qty": sell_qty,
    }

# ────────────────────────────────────────────────────────────────────────────
# FASTENING & JOINING  (shared material attr on 'fastening-joining')
# ────────────────────────────────────────────────────────────────────────────

THREAD_SIZES_SMALL = [("#4-40","#4-40"),("#6-32","#6-32"),("#8-32","#8-32"),
                      ("#10-24","#10-24"),("#10-32","#10-32")]
THREAD_SIZES_MED   = [("1/4-20",'1/4"-20'),("5/16-18",'5/16"-18'),
                      ("3/8-16",'3/8"-16'),("1/2-13",'1/2"-13')]
THREAD_SIZES_LG    = [("5/8-11",'5/8"-11'),("3/4-10",'3/4"-10')]
THREAD_TYPES       = [("UNC","Coarse (UNC)"),("UNF","Fine (UNF)")]

# ── Machine Screws ──
CATEGORIES.append({
    "slug": "machine-screws",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size", options=THREAD_SIZES_SMALL+THREAD_SIZES_MED[:2],
             tooltip="Nominal diameter x pitch"),
        attr("length_in","Length","number","range", unit="in.", tooltip="Overall screw length"),
        attr("head_type","Head Type",
             options=[("pan","Pan"),("flat-82","Flat (82°)"),("round","Round"),("truss","Truss")]),
        attr("drive_type","Drive Type",
             options=[("phillips","Phillips"),("slotted","Slotted"),("combo","Combination")]),
        attr("thread_type","Thread Type", options=THREAD_TYPES),
    ],
    "groups": [
        group("Machine Screws","Zinc-Plated Steel, Phillips Pan Head",
              "machine-screws-zinc-pan-phillips",
              "General-purpose machine screws with phillips drive and pan head. Zinc plating for mild corrosion resistance.",
              sort_primary="thread_size", sort_secondary="length_in",
              uniform={"material":"zinc-steel","head_type":"pan","drive_type":"phillips","thread_type":"UNC"},
              varying_enum={"thread_size":["#6-32","#8-32","#10-24","1/4-20"]},
              varying_num={"length_in":[0.50,0.75,1.00,1.50]},
              part_prefix="91772A", base_price=0.025, weight_base=0.0008),
        group("Machine Screws","18-8 Stainless Steel, Phillips Pan Head",
              "machine-screws-ss-pan-phillips",
              "Corrosion-resistant machine screws in 18-8 stainless steel. Phillips pan head.",
              sort_primary="thread_size", sort_secondary="length_in",
              uniform={"material":"18-8-ss","head_type":"pan","drive_type":"phillips","thread_type":"UNC"},
              varying_enum={"thread_size":["#6-32","#8-32","#10-24"]},
              varying_num={"length_in":[0.50,0.75,1.00]},
              part_prefix="91735A", base_price=0.060, weight_base=0.0008),
    ],
})

# ── Sheet Metal Screws ──
CATEGORIES.append({
    "slug": "sheet-metal-screws",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size",
             options=[("#6","#6"),("#8","#8"),("#10","#10"),("#12","#12"),("1/4",'1/4"')],
             tooltip="Nominal screw size"),
        attr("length_in","Length","number","range", unit="in."),
        attr("head_type","Head Type",
             options=[("hex-washer","Hex Washer"),("pan","Pan"),("flat-82","Flat (82°)")]),
        attr("drive_type","Drive Type",
             options=[("slotted-hex","Slotted Hex"),("phillips","Phillips"),("combo","Combination")]),
        attr("point_type","Point Type",
             options=[("sharp","Sharp (Type A)"),("self-drill","Self-Drilling (Type BSD)")]),
    ],
    "groups": [
        group("Sheet Metal Screws","Zinc-Plated Steel, Hex Washer Head",
              "sheet-metal-screws-zinc-hex-washer",
              "Sharp-point sheet metal screws for fastening sheet metal, fiberglass, and plastic. Hex washer head with slotted hex drive.",
              sort_primary="thread_size", sort_secondary="length_in",
              uniform={"material":"zinc-steel","head_type":"hex-washer","drive_type":"slotted-hex","point_type":"sharp"},
              varying_enum={"thread_size":["#8","#10","#12","1/4"]},
              varying_num={"length_in":[0.50,0.75,1.00,1.50]},
              part_prefix="90190A", base_price=0.030, weight_base=0.0012),
    ],
})

# ── Wood Screws ──
CATEGORIES.append({
    "slug": "wood-screws",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size",
             options=[("#6","#6"),("#8","#8"),("#10","#10"),("#12","#12")]),
        attr("length_in","Length","number","range", unit="in."),
        attr("head_type","Head Type",
             options=[("flat-82","Flat (82°)"),("round","Round"),("pan","Pan")]),
        attr("drive_type","Drive Type",
             options=[("phillips","Phillips"),("square","Square (Robertson)"),("star","Star (Torx)")]),
    ],
    "groups": [
        group("Wood Screws","Zinc-Plated Steel, Phillips Flat Head",
              "wood-screws-zinc-flat-phillips",
              "Standard wood screws with deep coarse threads for strong grip in wood. Phillips flat head sits flush with surface.",
              sort_primary="thread_size", sort_secondary="length_in",
              uniform={"material":"zinc-steel","head_type":"flat-82","drive_type":"phillips"},
              varying_enum={"thread_size":["#6","#8","#10"]},
              varying_num={"length_in":[0.75,1.00,1.25,1.50,2.00]},
              part_prefix="90030A", base_price=0.022, weight_base=0.0010),
    ],
})

# ── Set Screws ──
CATEGORIES.append({
    "slug": "set-screws",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size", options=THREAD_SIZES_SMALL[2:]+THREAD_SIZES_MED[:3],
             tooltip="Nominal diameter x pitch"),
        attr("length_in","Length","number","range", unit="in."),
        attr("point_type","Point Type",
             options=[("cup","Cup"),("cone","Cone"),("flat","Flat"),("dog","Dog"),("half-dog","Half Dog")]),
        attr("drive_type","Drive Type",
             options=[("hex-socket","Hex Socket")]),
    ],
    "groups": [
        group("Set Screws","Alloy Steel, Black Oxide, Cup Point",
              "set-screws-alloy-cup",
              "Alloy steel set screws with cup point for maximum holding power on shafts. Black oxide finish. Class 45H.",
              sort_primary="thread_size", sort_secondary="length_in",
              uniform={"material":"alloy-steel","point_type":"cup","drive_type":"hex-socket"},
              varying_enum={"thread_size":["#8-32","#10-24","1/4-20","5/16-18","3/8-16"]},
              varying_num={"length_in":[0.25,0.375,0.50,0.75]},
              part_prefix="92311A", base_price=0.045, weight_base=0.0006),
    ],
})

# ── Carriage Bolts ──
CATEGORIES.append({
    "slug": "carriage-bolts",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size", options=THREAD_SIZES_MED+THREAD_SIZES_LG[:1]),
        attr("length_in","Length","number","range", unit="in."),
        attr("grade","Grade", options=[("grade-2","Grade 2"),("grade-5","Grade 5")]),
        attr("thread_type","Thread Type", options=THREAD_TYPES),
    ],
    "groups": [
        group("Carriage Bolts","Zinc-Plated Steel, Grade 5",
              "carriage-bolts-zinc-grade5",
              "Round-head carriage bolts with square neck that locks into wood to prevent spinning. Zinc-plated Grade 5 steel.",
              sort_primary="thread_size", sort_secondary="length_in",
              uniform={"material":"zinc-steel","grade":"grade-5","thread_type":"UNC"},
              varying_enum={"thread_size":["1/4-20","5/16-18","3/8-16","1/2-13"]},
              varying_num={"length_in":[1.00,1.50,2.00,3.00]},
              part_prefix="90185A", base_price=0.08, weight_base=0.004),
    ],
})

# ── Lock Nuts ──
CATEGORIES.append({
    "slug": "lock-nuts",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size", options=THREAD_SIZES_MED+THREAD_SIZES_LG),
        attr("width_af","Width Across Flats","number","range", unit="in."),
        attr("lock_type","Lock Type",
             options=[("nylon-insert","Nylon Insert"),("all-metal","All-Metal Prevailing Torque")]),
        attr("thread_type","Thread Type", options=THREAD_TYPES),
    ],
    "groups": [
        group("Lock Nuts","Zinc-Plated Steel, Nylon Insert",
              "lock-nuts-zinc-nylon-insert",
              "Nylon insert lock nuts resist vibration loosening. Zinc-plated steel body. Reusable up to 5 times at reduced torque.",
              sort_primary="thread_size",
              uniform={"material":"zinc-steel","lock_type":"nylon-insert","thread_type":"UNC"},
              varying_enum={"thread_size":["1/4-20","5/16-18","3/8-16","1/2-13","5/8-11","3/4-10"]},
              varying_num={"width_af":[0.438,0.500,0.563,0.750,0.938,1.125]},
              part_prefix="90630A", base_price=0.040, weight_base=0.004),
        group("Lock Nuts","18-8 Stainless Steel, Nylon Insert",
              "lock-nuts-ss-nylon-insert",
              "Corrosion-resistant nylon insert lock nuts in 18-8 stainless steel. For outdoor and chemical environments.",
              sort_primary="thread_size",
              uniform={"material":"18-8-ss","lock_type":"nylon-insert","thread_type":"UNC"},
              varying_enum={"thread_size":["1/4-20","5/16-18","3/8-16","1/2-13","5/8-11"]},
              varying_num={"width_af":[0.438,0.500,0.563,0.750,0.938]},
              part_prefix="94645A", base_price=0.095, weight_base=0.004),
    ],
})

# ── Wing Nuts ──
CATEGORIES.append({
    "slug": "wing-nuts",
    "material_from": "fastening-joining",
    "attrs": [
        attr("thread_size","Thread Size", options=THREAD_SIZES_MED),
        attr("wing_spread","Wing Spread","number","range", unit="in."),
        attr("thread_type","Thread Type", options=THREAD_TYPES),
    ],
    "groups": [
        group("Wing Nuts","Zinc-Plated Steel",
              "wing-nuts-zinc",
              "Standard stamped wing nuts for hand-tightened connections. Zinc-plated steel.",
              sort_primary="thread_size",
              uniform={"material":"zinc-steel","thread_type":"UNC"},
              varying_enum={"thread_size":["1/4-20","5/16-18","3/8-16","1/2-13"]},
              varying_num={"wing_spread":[0.875,1.000,1.125,1.438]},
              part_prefix="90865A", base_price=0.06, weight_base=0.005),
    ],
})

# ── Fender Washers ──
CATEGORIES.append({
    "slug": "fender-washers",
    "material_from": "fastening-joining",
    "attrs": [
        attr("bolt_size","For Bolt Size",
             options=[("#10","#10"),("1/4",'1/4"'),("5/16",'5/16"'),("3/8",'3/8"'),("1/2",'1/2"')]),
        attr("od_in","OD","number","range", unit="in."),
        attr("thickness_in","Thickness","number","range", unit="in."),
    ],
    "groups": [
        group("Fender Washers","Zinc-Plated Steel",
              "fender-washers-zinc",
              "Extra-wide flat washers that spread load over a larger area. Ideal for soft materials or oversized holes.",
              sort_primary="bolt_size",
              uniform={"material":"zinc-steel"},
              varying_enum={"bolt_size":["#10","1/4","5/16","3/8","1/2"]},
              varying_num={"od_in":[0.750,1.000,1.062,1.250,1.500],
                           "thickness_in":[0.049,0.049,0.065,0.065,0.065]},
              part_prefix="90166A", base_price=0.020, weight_base=0.003),
    ],
})

# ── Lock Washers ──
CATEGORIES.append({
    "slug": "lock-washers",
    "material_from": "fastening-joining",
    "attrs": [
        attr("bolt_size","For Bolt Size",
             options=[("#10","#10"),("1/4",'1/4"'),("5/16",'5/16"'),("3/8",'3/8"'),
                      ("1/2",'1/2"'),("5/8",'5/8"'),("3/4",'3/4"')]),
        attr("type","Type", options=[("split","Split Lock"),("external-tooth","External Tooth")]),
    ],
    "groups": [
        group("Lock Washers","Zinc-Plated Steel, Split Lock",
              "lock-washers-zinc-split",
              "Split-ring lock washers create spring tension to resist loosening. Zinc-plated steel.",
              sort_primary="bolt_size",
              uniform={"material":"zinc-steel","type":"split"},
              varying_enum={"bolt_size":["#10","1/4","5/16","3/8","1/2","5/8","3/4"]},
              part_prefix="92146A", base_price=0.012, weight_base=0.001),
    ],
})

# ── Blind Rivets ──
CATEGORIES.append({
    "slug": "blind-rivets",
    "material_from": "fastening-joining",
    "attrs": [
        attr("diameter","Diameter","enum","checkbox",
             options=[("1/8",'1/8"'),("5/32",'5/32"'),("3/16",'3/16"'),("1/4",'1/4"')]),
        attr("grip_range","Max Grip Range","number","range", unit="in."),
        attr("body_material","Body Material",
             options=[("aluminum","Aluminum"),("steel","Steel"),("stainless","Stainless Steel")]),
        attr("mandrel_material","Mandrel Material",
             options=[("steel","Steel"),("stainless","Stainless Steel")]),
    ],
    "groups": [
        group("Blind Rivets","Aluminum Body, Steel Mandrel",
              "blind-rivets-aluminum-steel",
              "Standard aluminum blind (pop) rivets with steel mandrel. Lightweight, corrosion-resistant. For sheet metal, plastic, and fiberglass.",
              sort_primary="diameter", sort_secondary="grip_range",
              uniform={"material":"nylon","body_material":"aluminum","mandrel_material":"steel"},
              varying_enum={"diameter":["1/8","5/32","3/16"]},
              varying_num={"grip_range":[0.188,0.312,0.500]},
              part_prefix="97525A", base_price=0.018, weight_base=0.001),
    ],
})

# ── Dowel Pins ──
CATEGORIES.append({
    "slug": "dowel-pins",
    "material_from": "fastening-joining",
    "attrs": [
        attr("diameter","Diameter","enum","checkbox",
             options=[("1/16",'1/16"'),("3/32",'3/32"'),("1/8",'1/8"'),("5/32",'5/32"'),
                      ("3/16",'3/16"'),("1/4",'1/4"'),("5/16",'5/16"'),("3/8",'3/8"')]),
        attr("length_in","Length","number","range", unit="in."),
    ],
    "groups": [
        group("Dowel Pins","Alloy Steel, Hardened",
              "dowel-pins-alloy-hardened",
              "Precision-ground alloy steel dowel pins. Hardened to Rc 60-62. For accurate alignment of mating parts.",
              sort_primary="diameter", sort_secondary="length_in",
              uniform={"material":"alloy-steel"},
              varying_enum={"diameter":["1/8","3/16","1/4","5/16"]},
              varying_num={"length_in":[0.50,0.75,1.00,1.50]},
              part_prefix="93600A", base_price=0.12, weight_base=0.002),
    ],
})

# ── Spring Pins ──
CATEGORIES.append({
    "slug": "spring-pins",
    "material_from": "fastening-joining",
    "attrs": [
        attr("diameter","Diameter","enum","checkbox",
             options=[("1/16",'1/16"'),("3/32",'3/32"'),("1/8",'1/8"'),
                      ("5/32",'5/32"'),("3/16",'3/16"'),("1/4",'1/4"')]),
        attr("length_in","Length","number","range", unit="in."),
        attr("type","Type", options=[("slotted","Slotted"),("coiled","Coiled")]),
    ],
    "groups": [
        group("Spring Pins","Carbon Steel, Slotted",
              "spring-pins-carbon-slotted",
              "Slotted spring pins (roll pins) compress when driven into hole. Carbon steel, zinc-plated.",
              sort_primary="diameter", sort_secondary="length_in",
              uniform={"material":"zinc-steel","type":"slotted"},
              varying_enum={"diameter":["1/16","3/32","1/8","5/32","3/16"]},
              varying_num={"length_in":[0.375,0.50,0.75,1.00]},
              part_prefix="92383A", base_price=0.015, weight_base=0.0005),
    ],
})

# ── External Retaining Rings ──
CATEGORIES.append({
    "slug": "external-retaining-rings",
    "material_from": "fastening-joining",
    "attrs": [
        attr("shaft_size","Shaft Diameter","enum","checkbox",
             options=[("3/16",'3/16"'),("1/4",'1/4"'),("5/16",'5/16"'),("3/8",'3/8"'),
                      ("1/2",'1/2"'),("5/8",'5/8"'),("3/4",'3/4"'),("1",'1"')]),
        attr("thickness_in","Thickness","number","range", unit="in."),
    ],
    "groups": [
        group("External Retaining Rings","Carbon Steel, Phosphate Finish",
              "external-retaining-rings-carbon",
              "Standard external retaining rings (snap rings) for grooved shafts. Carbon steel with phosphate finish.",
              sort_primary="shaft_size",
              uniform={"material":"plain-steel"},
              varying_enum={"shaft_size":["1/4","3/8","1/2","5/8","3/4","1"]},
              varying_num={"thickness_in":[0.025,0.035,0.042,0.050,0.062,0.075]},
              part_prefix="97633A", base_price=0.08, weight_base=0.001),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# RAW MATERIALS
# ────────────────────────────────────────────────────────────────────────────

CATEGORIES.append({
    "slug": "steel-bars",
    "material_from": None,
    "attrs": [
        attr("alloy","Alloy",
             options=[("1018","1018"),("1045","1045"),("4140","4140"),("A36","A36")]),
        attr("diameter_in","Diameter","number","range", unit="in.", tooltip="Bar diameter"),
        attr("length_ft","Length","number","range", unit="ft.", tooltip="Bar length"),
        attr("shape","Shape", options=[("round","Round"),("hex","Hex"),("square","Square")]),
        attr("finish","Finish",
             options=[("cold-drawn","Cold Drawn"),("hot-rolled","Hot Rolled"),("ground","Precision Ground")]),
    ],
    "groups": [
        group("Steel Bars","1018 Carbon Steel, Cold Drawn Round",
              "steel-bars-1018-cold-round",
              "General-purpose 1018 cold-drawn round bar. Good machinability and weldability. ASTM A108.",
              sort_primary="diameter_in", sort_secondary="length_ft",
              uniform={"alloy":"1018","shape":"round","finish":"cold-drawn"},
              varying_num={"diameter_in":[0.250,0.375,0.500,0.625,0.750,1.000],
                           "length_ft":[1.0,2.0,3.0]},
              part_prefix="8920K", base_price=3.50, weight_base=0.22,
              sell_unit="Each", engineering_note="Tolerance: +0.000/-0.002 in. for diameters up to 1 in."),
    ],
})

CATEGORIES.append({
    "slug": "aluminum-sheets",
    "material_from": None,
    "attrs": [
        attr("alloy","Alloy",
             options=[("6061-T6","6061-T6"),("5052-H32","5052-H32"),("3003-H14","3003-H14")]),
        attr("thickness_in","Thickness","number","range", unit="in."),
        attr("width_in","Width","number","range", unit="in."),
        attr("length_in","Length","number","range", unit="in."),
    ],
    "groups": [
        group("Aluminum Sheets","6061-T6",
              "aluminum-sheets-6061-t6",
              "Multipurpose 6061-T6 aluminum sheet. Excellent strength-to-weight ratio. Readily machinable and weldable.",
              sort_primary="thickness_in",
              uniform={"alloy":"6061-T6"},
              varying_num={"thickness_in":[0.032,0.063,0.090,0.125,0.190,0.250],
                           "width_in":[12.0,12.0,12.0,12.0,12.0,12.0],
                           "length_in":[12.0,12.0,24.0,24.0,24.0,24.0]},
              part_prefix="89015K", base_price=5.80, weight_base=0.10),
    ],
})

CATEGORIES.append({
    "slug": "nylon-sheets",
    "material_from": None,
    "attrs": [
        attr("type","Type",
             options=[("6-6","Type 6/6 (Natural)"),("6","Type 6 (Cast)"),("md","MD (Oil-Filled)")]),
        attr("thickness_in","Thickness","number","range", unit="in."),
        attr("width_in","Width","number","range", unit="in."),
        attr("length_in","Length","number","range", unit="in."),
    ],
    "groups": [
        group("Nylon Sheets","Type 6/6 Natural",
              "nylon-sheets-66-natural",
              "Multipurpose nylon 6/6 sheet stock. High strength, abrasion resistance, and low friction. FDA compliant for food contact.",
              sort_primary="thickness_in",
              uniform={"type":"6-6"},
              varying_num={"thickness_in":[0.063,0.125,0.250,0.500,0.750,1.000],
                           "width_in":[12.0,12.0,12.0,24.0,24.0,24.0],
                           "length_in":[12.0,24.0,24.0,24.0,24.0,24.0]},
              part_prefix="8538K", base_price=8.20, weight_base=0.05),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# PLUMBING  (shared material attr on 'plumbing')
# ────────────────────────────────────────────────────────────────────────────

PIPE_SIZES = [("1/4",'1/4"'),("3/8",'3/8"'),("1/2",'1/2"'),("3/4",'3/4"'),
              ("1",'1"'),("1-1/4",'1-1/4"'),("1-1/2",'1-1/2"'),("2",'2"')]

CATEGORIES.append({
    "slug": "pipe-elbows",
    "material_from": "plumbing",
    "attrs": [
        attr("pipe_size","Pipe Size", options=PIPE_SIZES[:6]),
        attr("angle","Angle", options=[("90","90°"),("45","45°")]),
        attr("connection_type","Connection Type",
             options=[("npt-female","NPT Female"),("npt-male-female","NPT Male x Female")]),
    ],
    "groups": [
        group("Pipe Elbows","Malleable Iron, Black, 90°, NPT Female",
              "pipe-elbows-malleable-90-npt",
              "Standard 90-degree pipe elbows in black malleable iron. Class 150. NPT female threads both ends.",
              sort_primary="pipe_size",
              uniform={"material":"carbon-steel","angle":"90","connection_type":"npt-female"},
              varying_enum={"pipe_size":["1/4","3/8","1/2","3/4","1","1-1/4"]},
              part_prefix="44605K", base_price=1.20, weight_base=0.08),
    ],
})

CATEGORIES.append({
    "slug": "gate-valves",
    "material_from": "plumbing",
    "attrs": [
        attr("pipe_size","Pipe Size", options=PIPE_SIZES[:6]),
        attr("connection_type","Connection Type",
             options=[("npt-threaded","NPT Threaded"),("solder","Solder")]),
        attr("max_pressure_psi","Max Pressure","number","range", unit="psi"),
        attr("handle_type","Handle Type",
             options=[("rising-stem","Rising Stem Handwheel"),("non-rising","Non-Rising Stem")]),
    ],
    "groups": [
        group("Gate Valves","Brass, NPT Threaded",
              "gate-valves-brass-npt",
              "Full-bore brass gate valves with rising stem handwheel. Lead-free per NSF/ANSI 372. For water, oil, and gas.",
              sort_primary="pipe_size",
              uniform={"material":"brass","connection_type":"npt-threaded","handle_type":"rising-stem"},
              varying_enum={"pipe_size":["1/2","3/4","1","1-1/4"]},
              varying_num={"max_pressure_psi":[200.0,200.0,200.0,150.0]},
              part_prefix="47305T", base_price=9.50, weight_base=0.40),
    ],
})

CATEGORIES.append({
    "slug": "compression-fittings",
    "material_from": "plumbing",
    "attrs": [
        attr("tube_od","Tube OD","enum","checkbox",
             options=[("1/8",'1/8"'),("3/16",'3/16"'),("1/4",'1/4"'),("3/8",'3/8"'),
                      ("1/2",'1/2"'),("5/8",'5/8"'),("3/4",'3/4"')]),
        attr("fitting_type","Fitting Type",
             options=[("union","Union"),("elbow","Elbow"),("tee","Tee"),("adapter-male","Male Adapter NPT")]),
    ],
    "groups": [
        group("Compression Fittings","Brass Unions",
              "compression-fittings-brass-union",
              "Brass compression tube fittings — no soldering or flaring required. Nut, ferrule, and body included.",
              sort_primary="tube_od",
              uniform={"material":"brass","fitting_type":"union"},
              varying_enum={"tube_od":["1/4","3/8","1/2","5/8","3/4"]},
              part_prefix="5182K", base_price=2.80, weight_base=0.03),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# ELECTRICAL
# ────────────────────────────────────────────────────────────────────────────

CATEGORIES.append({
    "slug": "hookup-wire",
    "material_from": None,
    "attrs": [
        attr("gauge_awg","Wire Gauge","enum","checkbox",
             options=[("22","22 AWG"),("20","20 AWG"),("18","18 AWG"),("16","16 AWG"),
                      ("14","14 AWG"),("12","12 AWG"),("10","10 AWG")]),
        attr("insulation","Insulation",
             options=[("pvc","PVC"),("ptfe","PTFE"),("silicone","Silicone")]),
        attr("conductor","Conductor",
             options=[("solid-copper","Solid Copper"),("stranded-copper","Stranded Copper"),
                      ("tinned-copper","Tinned Copper")]),
        attr("voltage_rating","Voltage Rating","enum","checkbox",
             options=[("300","300V"),("600","600V")]),
        attr("length_ft","Length","number","range", unit="ft."),
    ],
    "groups": [
        group("Hookup Wire","Solid Copper, PVC Insulation, 600V",
              "hookup-wire-solid-pvc-600v",
              "UL 1015 rated hookup wire. Solid copper conductor with PVC insulation. 600V, 105°C. CSA and RoHS compliant.",
              sort_primary="gauge_awg", sort_secondary="length_ft",
              uniform={"insulation":"pvc","conductor":"solid-copper","voltage_rating":"600"},
              varying_enum={"gauge_awg":["22","20","18","16","14"]},
              varying_num={"length_ft":[25.0,100.0,500.0]},
              part_prefix="8054K", base_price=4.20, weight_base=0.15,
              sell_unit="Spool"),
    ],
})

CATEGORIES.append({
    "slug": "toggle-switches",
    "material_from": None,
    "attrs": [
        attr("poles","Configuration",
             options=[("spst","SPST (On-Off)"),("spdt","SPDT (On-On)"),
                      ("dpst","DPST (On-Off)"),("dpdt","DPDT (On-On)")]),
        attr("amperage","Current Rating","enum","checkbox",
             options=[("5","5A"),("10","10A"),("15","15A"),("20","20A")]),
        attr("voltage_ac","AC Voltage","enum","checkbox",
             options=[("125","125 VAC"),("250","250 VAC")]),
        attr("mounting","Mounting",
             options=[("panel","Panel Mount"),("pcb","PCB Mount")]),
    ],
    "groups": [
        group("Toggle Switches","Panel Mount, Screw Terminal",
              "toggle-switches-panel-screw",
              "Industrial toggle switches with screw terminal connections. Nickel-plated brass bushing. 1/2 in. mounting hole.",
              sort_primary="poles", sort_secondary="amperage",
              uniform={"mounting":"panel"},
              varying_enum={"poles":["spst","spdt","dpst","dpdt"],
                            "amperage":["10","20"]},
              part_prefix="7203K", base_price=3.40, weight_base=0.03),
    ],
})

CATEGORIES.append({
    "slug": "fuses",
    "material_from": None,
    "attrs": [
        attr("amperage","Current Rating","enum","checkbox",
             options=[("1","1A"),("2","2A"),("3","3A"),("5","5A"),("10","10A"),
                      ("15","15A"),("20","20A"),("30","30A")]),
        attr("voltage","Voltage Rating","enum","checkbox",
             options=[("250","250V"),("600","600V")]),
        attr("speed","Speed",
             options=[("fast","Fast-Acting"),("slow","Slow-Blow (Time Delay)")]),
        attr("size","Size",
             options=[("midget","Midget (10x38mm)"),("standard","Standard (1/4x1-1/4 in.)")]),
    ],
    "groups": [
        group("Fuses","Fast-Acting, Midget (10x38mm), 600V",
              "fuses-fast-midget-600v",
              "Class CC / Class J fast-acting midget fuses. 600V AC rated. Current-limiting. UL listed.",
              sort_primary="amperage",
              uniform={"voltage":"600","speed":"fast","size":"midget"},
              varying_enum={"amperage":["1","2","3","5","10","15","20","30"]},
              part_prefix="68985K", base_price=2.10, weight_base=0.01),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# HAND TOOLS
# ────────────────────────────────────────────────────────────────────────────

CATEGORIES.append({
    "slug": "combination-wrenches",
    "material_from": None,
    "attrs": [
        attr("size","Size","enum","checkbox",
             options=[("1/4",'1/4"'),("5/16",'5/16"'),("3/8",'3/8"'),("7/16",'7/16"'),
                      ("1/2",'1/2"'),("9/16",'9/16"'),("5/8",'5/8"'),("11/16",'11/16"'),
                      ("3/4",'3/4"'),("7/8",'7/8"'),("15/16",'15/16"'),("1",'1"')]),
        attr("system","System", options=[("sae","SAE (Inch)"),("metric","Metric")]),
        attr("finish","Finish",
             options=[("chrome","Full Chrome"),("satin","Satin Chrome"),("black","Black Chrome")]),
    ],
    "groups": [
        group("Combination Wrenches","Chrome Vanadium Steel, SAE",
              "combination-wrenches-sae-chrome",
              "Professional-grade combination wrenches. Chrome vanadium steel with full chrome finish. 12-point box end, open end.",
              sort_primary="size",
              uniform={"system":"sae","finish":"chrome"},
              varying_enum={"size":["1/4","5/16","3/8","7/16","1/2","9/16","5/8","3/4","7/8","1"]},
              part_prefix="5251A", base_price=4.80, weight_base=0.06),
    ],
})

CATEGORIES.append({
    "slug": "adjustable-wrenches",
    "material_from": None,
    "attrs": [
        attr("length_in","Overall Length","number","range", unit="in."),
        attr("jaw_capacity","Max Jaw Opening","number","range", unit="in."),
        attr("finish","Finish",
             options=[("chrome","Chrome"),("black-phosphate","Black Phosphate")]),
    ],
    "groups": [
        group("Adjustable Wrenches","Chrome Plated, Cushion Grip",
              "adjustable-wrenches-chrome-cushion",
              "Drop-forged chrome vanadium steel adjustable wrenches. Chrome plated with cushion grip handle.",
              sort_primary="length_in",
              uniform={"finish":"chrome"},
              varying_num={"length_in":[6.0,8.0,10.0,12.0,15.0],
                           "jaw_capacity":[0.750,1.000,1.250,1.500,1.875]},
              part_prefix="52985A", base_price=9.80, weight_base=0.35),
    ],
})

CATEGORIES.append({
    "slug": "phillips-screwdrivers",
    "material_from": None,
    "attrs": [
        attr("tip_size","Tip Size","enum","checkbox",
             options=[("#0","#0"),("#1","#1"),("#2","#2"),("#3","#3"),("#4","#4")]),
        attr("blade_length","Blade Length","number","range", unit="in."),
        attr("handle_type","Handle Type",
             options=[("cushion","Cushion Grip"),("acetate","Acetate"),("insulated","Insulated 1000V")]),
    ],
    "groups": [
        group("Phillips Screwdrivers","Cushion Grip",
              "phillips-screwdrivers-cushion",
              "Professional phillips screwdrivers with cushion grip handles. Chrome vanadium steel blade with black oxide tip.",
              sort_primary="tip_size", sort_secondary="blade_length",
              uniform={"handle_type":"cushion"},
              varying_enum={"tip_size":["#0","#1","#2","#3"]},
              varying_num={"blade_length":[2.5,3.0,4.0,6.0]},
              part_prefix="5724A", base_price=5.20, weight_base=0.05),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# POWER TRANSMISSION
# ────────────────────────────────────────────────────────────────────────────

CATEGORIES.append({
    "slug": "ball-bearings",
    "material_from": None,
    "attrs": [
        attr("bore_mm","Bore Diameter","number","range", unit="mm"),
        attr("od_mm","Outer Diameter","number","range", unit="mm"),
        attr("width_mm","Width","number","range", unit="mm"),
        attr("bearing_type","Type",
             options=[("deep-groove","Deep Groove"),("angular-contact","Angular Contact")]),
        attr("seal_type","Seal/Shield",
             options=[("open","Open"),("2rs","Double Sealed (2RS)"),("zz","Double Shielded (ZZ)")]),
    ],
    "groups": [
        group("Ball Bearings","Deep Groove, Double Sealed",
              "ball-bearings-deep-groove-2rs",
              "Deep groove radial ball bearings with double rubber seals. Pre-lubricated. ABEC-1 tolerance. Suitable for electric motors, pumps, and general machinery.",
              sort_primary="bore_mm",
              uniform={"bearing_type":"deep-groove","seal_type":"2rs"},
              varying_num={"bore_mm":[6,8,10,12,15,17,20,25,30,35],
                           "od_mm":[19,22,26,32,35,40,47,52,62,72],
                           "width_mm":[6,7,8,10,11,12,14,15,16,17]},
              part_prefix="57155K", base_price=3.20, weight_base=0.01),
    ],
})

CATEGORIES.append({
    "slug": "shaft-collars",
    "material_from": None,
    "attrs": [
        attr("bore_in","Bore Diameter","number","range", unit="in."),
        attr("od_in","Outer Diameter","number","range", unit="in."),
        attr("width_in","Width","number","range", unit="in."),
        attr("collar_type","Type",
             options=[("one-piece-clamp","One-Piece Clamp"),("two-piece-clamp","Two-Piece Clamp"),
                      ("set-screw","Set Screw")]),
        attr("collar_material","Material",
             options=[("steel-zinc","Steel, Zinc Plated"),("steel-black","Steel, Black Oxide"),
                      ("stainless","Stainless Steel"),("aluminum","Aluminum")]),
    ],
    "groups": [
        group("Shaft Collars","Steel, Two-Piece Clamp-On",
              "shaft-collars-steel-2pc-clamp",
              "Two-piece clamp-on shaft collars install without disassembly. Steel with zinc plating. Won't mar the shaft.",
              sort_primary="bore_in",
              uniform={"collar_type":"two-piece-clamp","collar_material":"steel-zinc"},
              varying_num={"bore_in":[0.250,0.375,0.500,0.625,0.750,1.000,1.250,1.500],
                           "od_in":[0.750,0.875,1.125,1.250,1.500,1.750,2.000,2.500],
                           "width_in":[0.312,0.375,0.437,0.437,0.500,0.562,0.625,0.750]},
              part_prefix="6166K", base_price=2.40, weight_base=0.04),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# HARDWARE
# ────────────────────────────────────────────────────────────────────────────

CATEGORIES.append({
    "slug": "compression-springs",
    "material_from": None,
    "attrs": [
        attr("od_in","Outer Diameter","number","range", unit="in."),
        attr("free_length","Free Length","number","range", unit="in."),
        attr("wire_diameter","Wire Diameter","number","range", unit="in."),
        attr("spring_rate","Spring Rate","number","range", unit="lb/in."),
        attr("spring_material","Material",
             options=[("music-wire","Music Wire"),("stainless","Stainless Steel"),("chrome-silicon","Chrome Silicon")]),
        attr("end_type","End Type",
             options=[("closed-ground","Closed & Ground"),("closed","Closed"),("open","Open")]),
    ],
    "groups": [
        group("Compression Springs","Music Wire, Zinc Plated",
              "compression-springs-music-wire",
              "Standard compression springs in music wire with zinc plating. Closed and ground ends for flat seating.",
              sort_primary="od_in", sort_secondary="free_length",
              uniform={"spring_material":"music-wire","end_type":"closed-ground"},
              varying_num={"od_in":[0.240,0.360,0.480,0.600,0.720,0.960],
                           "free_length":[0.50,0.75,1.00,1.50,2.00,2.50],
                           "wire_diameter":[0.032,0.041,0.055,0.063,0.072,0.080],
                           "spring_rate":[2.5,4.8,8.2,10.5,14.0,22.0]},
              part_prefix="9657K", base_price=0.60, weight_base=0.005),
    ],
})

CATEGORIES.append({
    "slug": "neodymium-magnets",
    "material_from": None,
    "attrs": [
        attr("shape","Shape", options=[("disc","Disc"),("block","Block"),("ring","Ring")]),
        attr("diameter_in","Diameter","number","range", unit="in."),
        attr("thickness_in","Thickness","number","range", unit="in."),
        attr("pull_force_lb","Pull Force","number","range", unit="lb."),
        attr("grade","Grade", options=[("N35","N35"),("N42","N42"),("N52","N52")]),
        attr("coating","Coating", options=[("nickel","Nickel"),("epoxy","Epoxy"),("gold","Gold")]),
    ],
    "groups": [
        group("Neodymium Magnets","Disc, Nickel Plated",
              "neodymium-magnets-disc-nickel",
              "Rare-earth neodymium disc magnets with nickel plating. Extremely strong for their size. Max operating temp 176°F.",
              sort_primary="diameter_in", sort_secondary="pull_force_lb",
              uniform={"shape":"disc","coating":"nickel","grade":"N42"},
              varying_num={"diameter_in":[0.250,0.375,0.500,0.750,1.000],
                           "thickness_in":[0.063,0.063,0.125,0.125,0.250],
                           "pull_force_lb":[2.0,5.0,12.0,22.0,75.0]},
              part_prefix="5857K", base_price=0.80, weight_base=0.002),
    ],
})

# ────────────────────────────────────────────────────────────────────────────
# SAFETY SUPPLIES
# ────────────────────────────────────────────────────────────────────────────

CATEGORIES.append({
    "slug": "safety-glasses",
    "material_from": None,
    "attrs": [
        attr("lens_type","Lens Type",
             options=[("clear","Clear"),("gray","Gray (Tinted)"),("amber","Amber"),
                      ("indoor-outdoor","Indoor/Outdoor Mirror")]),
        attr("frame_color","Frame Color",
             options=[("black","Black"),("blue","Blue"),("clear","Clear")]),
        attr("coating","Lens Coating",
             options=[("anti-fog","Anti-Fog"),("anti-scratch","Anti-Scratch"),
                      ("anti-fog-scratch","Anti-Fog & Anti-Scratch")]),
        attr("standard","Standard",
             options=[("ansi-z87","ANSI Z87.1+"),("mil-spec","MIL-PRF-31013")]),
    ],
    "groups": [
        group("Safety Glasses","ANSI Z87.1+, Anti-Fog",
              "safety-glasses-z87-anti-fog",
              "Impact-resistant polycarbonate safety glasses. ANSI Z87.1+ rated. Lightweight wraparound design with anti-fog coating.",
              sort_primary="lens_type",
              uniform={"coating":"anti-fog","standard":"ansi-z87"},
              varying_enum={"lens_type":["clear","gray","amber","indoor-outdoor"],
                            "frame_color":["black","blue"]},
              part_prefix="22545T", base_price=4.50, weight_base=0.05),
    ],
})

CATEGORIES.append({
    "slug": "disposable-gloves",
    "material_from": None,
    "attrs": [
        attr("glove_material","Material",
             options=[("nitrile","Nitrile"),("latex","Latex"),("vinyl","Vinyl")]),
        attr("size","Size",
             options=[("S","Small"),("M","Medium"),("L","Large"),("XL","X-Large")]),
        attr("thickness_mil","Thickness","number","range", unit="mil"),
        attr("powdered","Powder",
             options=[("powder-free","Powder-Free"),("powdered","Powdered")]),
    ],
    "groups": [
        group("Disposable Gloves","Nitrile, Powder-Free",
              "disposable-gloves-nitrile-pf",
              "Industrial-grade nitrile disposable gloves. Powder-free, latex-free. Chemical and puncture resistant. 100 per box.",
              sort_primary="size",
              uniform={"glove_material":"nitrile","powdered":"powder-free"},
              varying_enum={"size":["S","M","L","XL"]},
              varying_num={"thickness_mil":[4.0,4.0,4.0,4.0]},
              part_prefix="7164T", base_price=12.50, weight_base=0.60,
              sell_unit="Box of 100", sell_qty=100),
    ],
})


# ════════════════════════════════════════════════════════════════════════════
# SQL generation
# ════════════════════════════════════════════════════════════════════════════

def generate_variants(grp):
    """
    Generate SKU variants from the cross-product of varying attributes.

    For numeric attrs, 'varying_num' values are either:
      - A list of scalars: cross-product with enum axes
      - A list aligned 1:1 with the first enum or num axis (parallel, not cross)

    If ALL varying attrs have the same length, we treat them as parallel
    (one SKU per index). Otherwise we cross-product the enum axes and
    pair with the matching numeric value.
    """
    ve = grp.get("varying_enum", {})
    vn = grp.get("varying_num", {})

    all_lens = [len(v) for v in ve.values()] + [len(v) for v in vn.values()]

    # If all axes have the same length, treat as parallel
    if all_lens and len(set(all_lens)) == 1:
        n = all_lens[0]
        variants = []
        for i in range(n):
            v = {}
            for key, vals in ve.items():
                v[key] = {"enum": vals[i]}
            for key, vals in vn.items():
                v[key] = {"num": vals[i]}
            variants.append(v)
        return variants

    # Otherwise, cross-product the enum axes, assign numeric by primary-axis index
    enum_keys = list(ve.keys())
    enum_vals = [ve[k] for k in enum_keys]

    if not enum_keys:
        # Only numeric attrs — treat as parallel
        n = all_lens[0] if all_lens else 0
        variants = []
        for i in range(n):
            v = {}
            for key, vals in vn.items():
                v[key] = {"num": vals[i % len(vals)]}
            variants.append(v)
        return variants

    variants = []
    for combo in itertools.product(*enum_vals):
        v = {}
        for j, key in enumerate(enum_keys):
            v[key] = {"enum": combo[j]}

        # For numeric attrs, if they're the same length as the FIRST enum axis,
        # use the index of the first enum value; otherwise use variant count
        idx = enum_vals[0].index(combo[0]) if combo[0] in enum_vals[0] else 0
        for key, vals in vn.items():
            v[key] = {"num": vals[idx % len(vals)]}
        variants.append(v)

    return variants


def gen_sku_name(grp, variant):
    """Build a human-readable SKU name from variant attributes."""
    parts = []
    for key in list(grp.get("varying_enum", {}).keys()) + list(grp.get("varying_num", {}).keys()):
        val = variant.get(key, {})
        if "enum" in val:
            parts.append(str(val["enum"]))
        elif "num" in val:
            v = val["num"]
            parts.append(f'{v}"' if isinstance(v, (int, float)) and v < 100 else str(v))
    base = grp["name"]
    if grp.get("subtitle"):
        base += ", " + grp["subtitle"]
    detail = " x ".join(parts) if len(parts) > 1 else (parts[0] if parts else "")
    return f"{detail} {base}".strip() if detail else base


def gen_part_number(prefix, index):
    """Generate a McMaster-style part number."""
    return f"{prefix}{index:03d}"


def generate_category_sql(cat):
    """Generate complete SQL for one leaf category."""
    slug = cat["slug"]
    mat_from = cat.get("material_from")
    attrs = cat.get("attrs", [])
    groups = cat.get("groups", [])

    lines = []
    lines.append(f"\n-- {'═' * 72}")
    lines.append(f"-- {slug}")
    lines.append(f"-- {'═' * 72}")

    # Skip if data already exists
    lines.append(f"""
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM product_groups pg
        JOIN categories c ON c.id = pg.category_id
        WHERE c.slug = '{esc(slug)}'
    ) THEN
        RAISE NOTICE 'Skipping {esc(slug)}: already has product data';
        RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM categories WHERE slug = '{esc(slug)}') THEN
        RAISE NOTICE 'Skipping {esc(slug)}: category not found';
        RETURN;
    END IF;
END $$;
""")

    # ── Attribute definitions ──
    if attrs:
        vals = []
        for i, a in enumerate(attrs):
            fso = i + 2
            tso = i + 1
            vals.append(
                f"    ('{esc(a['key'])}','{esc(a['label'])}',"
                f"{sql_val(a.get('unit'))},{sql_val(a['data_type'])},{sql_val(a['widget'])},"
                f"{sql_val(a['filterable'])},{fso},{sql_val(a['table_col'])},{tso},110,"
                f"{sql_val(a.get('tooltip'))})"
            )
        lines.append(f"""INSERT INTO attribute_definitions
    (category_id, key, label, unit_label, data_type, filter_widget,
     is_filterable, filter_sort_order, is_table_column, table_sort_order, table_column_width, tooltip)
SELECT c.id, v.key, v.label, v.ul, v.dt, v.fw, v.fil, v.fso, v.tab, v.tso, v.tcw, v.tip
FROM categories c, (VALUES
{','.join(vals)}
) AS v(key, label, ul, dt, fw, fil, fso, tab, tso, tcw, tip)
WHERE c.slug = '{esc(slug)}'
ON CONFLICT (category_id, key) DO NOTHING;
""")

    # ── Attribute options ──
    for a in attrs:
        if not a.get("options"):
            continue
        opt_vals = []
        for j, (val, display) in enumerate(a["options"]):
            opt_vals.append(f"    ('{esc(val)}','{esc(display)}',{j+1})")
        lines.append(f"""WITH attr AS (SELECT ad.id FROM attribute_definitions ad
              JOIN categories c ON c.id=ad.category_id
              WHERE ad.key='{esc(a['key'])}' AND c.slug='{esc(slug)}')
INSERT INTO attribute_options (attribute_id, value, display_value, sort_order)
SELECT attr.id, v.val, v.dv, v.so FROM attr, (VALUES
{','.join(opt_vals)}
) AS v(val, dv, so)
ON CONFLICT (attribute_id, value) DO NOTHING;
""")

    # ── Product groups ──
    for g in groups:
        lines.append(f"""INSERT INTO product_groups
    (category_id, name, subtitle, slug, description, engineering_note, default_sort_key)
SELECT c.id, '{esc(g['name'])}', '{esc(g['subtitle'])}', '{esc(g['slug'])}',
       '{esc(g['description'])}', {sql_val(g.get('engineering_note'))}, '{esc(g['sort_primary'])}'
FROM categories c WHERE c.slug = '{esc(slug)}'
ON CONFLICT (slug) DO NOTHING;
""")

    # ── Column configs ──
    lines.append(f"""WITH groups AS (SELECT pg.id FROM product_groups pg
                  JOIN categories c ON c.id = pg.category_id WHERE c.slug = '{esc(slug)}')
INSERT INTO product_group_columns (product_group_id, attribute_id, role, sort_order)
SELECT g.id, ad.id,
    CASE ad.key {' '.join(f"WHEN '{esc(groups[0]['sort_primary'])}' THEN 'sort_primary'" for _ in [1])}
    {f"WHEN '{esc(groups[0].get('sort_secondary', ''))}' THEN 'sort_secondary'" if groups[0].get('sort_secondary') else ''}
    ELSE 'column' END,
    ad.table_sort_order
FROM groups g
CROSS JOIN attribute_definitions ad
WHERE ad.category_id IN (
    SELECT c2.id FROM categories c2
    WHERE c2.path @> (SELECT path FROM categories WHERE slug='{esc(slug)}')
) AND ad.is_active = TRUE AND (ad.is_table_column = TRUE OR ad.is_filterable = TRUE)
ON CONFLICT DO NOTHING;
""")

    # ── SKUs + Attributes + Prices (one DO $$ block) ──
    lines.append("DO $$")
    lines.append("DECLARE")
    lines.append("    v_cat_id INT;")
    if mat_from:
        lines.append("    v_mat_parent_id INT;")
        lines.append("    v_mat_attr INT;")

    # Declare attr variables
    attr_vars = {}
    for a in attrs:
        var = f"v_{a['key']}"
        attr_vars[a['key']] = var
        lines.append(f"    {var} INT;")

    lines.append("BEGIN")
    lines.append(f"    SELECT id INTO v_cat_id FROM categories WHERE slug = '{esc(slug)}';")
    if mat_from:
        lines.append(f"    SELECT id INTO v_mat_parent_id FROM categories WHERE slug = '{esc(mat_from)}';")
        lines.append(f"    SELECT id INTO v_mat_attr FROM attribute_definitions WHERE key='material' AND category_id=v_mat_parent_id;")

    for a in attrs:
        lines.append(f"    SELECT id INTO {attr_vars[a['key']]} FROM attribute_definitions WHERE key='{esc(a['key'])}' AND category_id=v_cat_id;")

    for g in groups:
        g_slug = g["slug"]
        variants = generate_variants(g)
        prefix = g["part_prefix"]

        # ── Insert SKUs ──
        sku_vals = []
        for i, v in enumerate(variants):
            pn = gen_part_number(prefix, i + 1)
            nm = gen_sku_name(g, v)
            wt = g["weight_base"] * (1 + i * 0.15)
            sku_vals.append(f"        ('{esc(pn)}','{esc(nm)}',{wt:.4f})")

        lines.append(f"""
    -- SKUs for {g_slug}
    INSERT INTO skus (product_group_id, part_number, name, sell_unit, sell_qty, weight_lbs)
    SELECT pg.id, s.pn, s.nm, '{esc(g.get('sell_unit','Each'))}', {g.get('sell_qty',1)}, s.wt
    FROM product_groups pg, (VALUES
{','.join(sku_vals)}
    ) AS s(pn, nm, wt)
    WHERE pg.slug = '{esc(g_slug)}'
    ON CONFLICT (part_number) DO NOTHING;""")

        # ── Uniform attributes ──
        for attr_key, attr_val in g.get("uniform", {}).items():
            if attr_key == "material" and mat_from:
                lines.append(f"""
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, v_mat_attr, '{esc(attr_val)}',
           (SELECT id FROM attribute_options WHERE attribute_id=v_mat_attr AND value='{esc(attr_val)}')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id
    WHERE pg.slug='{esc(g_slug)}'
    ON CONFLICT DO NOTHING;""")
            elif attr_key in attr_vars:
                var = attr_vars[attr_key]
                # Check if this attr has options (enum) or is plain text
                a_def = next((a for a in attrs if a["key"] == attr_key), None)
                if a_def and a_def.get("options"):
                    lines.append(f"""
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, {var}, '{esc(attr_val)}',
           (SELECT id FROM attribute_options WHERE attribute_id={var} AND value='{esc(attr_val)}')
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id
    WHERE pg.slug='{esc(g_slug)}'
    ON CONFLICT DO NOTHING;""")
                else:
                    lines.append(f"""
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text)
    SELECT s.id, {var}, '{esc(attr_val)}'
    FROM skus s JOIN product_groups pg ON pg.id=s.product_group_id
    WHERE pg.slug='{esc(g_slug)}'
    ON CONFLICT DO NOTHING;""")

        # ── Varying enum attributes ──
        for attr_key, _ in g.get("varying_enum", {}).items():
            var = attr_vars.get(attr_key)
            if not var:
                continue
            ve_vals = []
            for i, v in enumerate(variants):
                pn = gen_part_number(prefix, i + 1)
                val = v.get(attr_key, {}).get("enum", "")
                ve_vals.append(f"        ('{esc(pn)}','{esc(val)}')")
            lines.append(f"""
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, option_id)
    SELECT s.id, {var}, v.val, ao.id FROM (VALUES
{','.join(ve_vals)}
    ) AS v(pn, val)
    JOIN skus s ON s.part_number=v.pn
    JOIN attribute_options ao ON ao.attribute_id={var} AND ao.value=v.val
    ON CONFLICT DO NOTHING;""")

        # ── Varying numeric attributes ──
        for attr_key, _ in g.get("varying_num", {}).items():
            var = attr_vars.get(attr_key)
            if not var:
                continue
            vn_vals = []
            for i, v in enumerate(variants):
                pn = gen_part_number(prefix, i + 1)
                num_val = v.get(attr_key, {}).get("num", 0)
                if isinstance(num_val, float):
                    text_val = f"{num_val:.3f}" if num_val < 1 else f"{num_val:.2f}"
                else:
                    text_val = str(num_val)
                vn_vals.append(f"        ('{esc(pn)}','{esc(text_val)}',{num_val})")
            lines.append(f"""
    INSERT INTO sku_attributes (sku_id, attribute_id, value_text, value_numeric)
    SELECT s.id, {var}, v.vt, v.vn FROM (VALUES
{','.join(vn_vals)}
    ) AS v(pn, vt, vn)
    JOIN skus s ON s.part_number=v.pn
    ON CONFLICT DO NOTHING;""")

        # ── Price tiers ──
        base = g["base_price"]
        lines.append(f"""
    -- Price tiers for {g_slug}
    INSERT INTO sku_price_tiers (sku_id, currency, qty_min, qty_max, unit_price)
    SELECT s.id, 'USD', t.mn, t.mx, {base} * t.mult * (1 + (ROW_NUMBER() OVER (ORDER BY s.sort_key) - 1) * 0.12)
    FROM skus s
    JOIN product_groups pg ON pg.id = s.product_group_id
    CROSS JOIN (VALUES
        (1,   24,  1.00::numeric),
        (25,  99,  0.80),
        (100, NULL,0.65)
    ) AS t(mn, mx, mult)
    WHERE pg.slug = '{esc(g_slug)}'
    ON CONFLICT DO NOTHING;""")

        # ── In-stock (75% of SKUs) ──
        lines.append(f"""
    -- Set ~75% of SKUs in stock
    UPDATE skus SET in_stock = TRUE
    WHERE id IN (
        SELECT s.id FROM skus s
        JOIN product_groups pg ON pg.id = s.product_group_id
        WHERE pg.slug = '{esc(g_slug)}'
        ORDER BY s.part_number
        LIMIT (SELECT GREATEST(1, (count(*) * 3 / 4)) FROM skus s2
               JOIN product_groups pg2 ON pg2.id = s2.product_group_id
               WHERE pg2.slug = '{esc(g_slug)}')
    );""")

    lines.append("\nEND $$;")
    return "\n".join(lines)


def main():
    header = """-- ════════════════════════════════════════════════════════════════════════════
-- Generated catalog seed data
-- Run:  python3 scripts/generate_catalog_data.py | docker exec -i storefront-db psql -U storefront -d storefront_dev
-- ════════════════════════════════════════════════════════════════════════════
SET client_min_messages TO WARNING;
BEGIN;
"""
    footer = """
COMMIT;
"""

    parts = [header]
    for cat in CATEGORIES:
        parts.append(generate_category_sql(cat))
    parts.append(footer)

    sys.stdout.write("\n".join(parts))


if __name__ == "__main__":
    main()
