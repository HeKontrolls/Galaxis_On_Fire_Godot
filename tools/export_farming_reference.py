"""Capture real Python farming interactions for the Godot compatibility check."""
import importlib.util
import json
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
source = ROOT.parent / "Galaxis_On_Fire" / "systems" / "farming.py"
spec = importlib.util.spec_from_file_location("original_farming", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
cases = []
for name, tile, above, below, tool, selected in [
    ("hoe grass", 1, 0, 2, "Hoe", "Dirt"),
    ("hoe dirt", 2, 0, 2, "Hoe", "Dirt"),
    ("covered dirt", 2, 3, 2, "Hoe", "Dirt"),
    ("water dry soil", 12, 0, 2, "Watering Can", "Dirt"),
    ("water wet soil", 13, 0, 2, "Watering Can", "Dirt"),
    ("plant dry soil", 12, 0, 2, "Pickaxe", "Crop Seeds"),
    ("plant wet soil", 13, 0, 2, "Pickaxe", "Crop Seeds"),
    ("plant air above soil", 0, 0, 12, "Hand", "Crop Seeds"),
    ("blocked planting", 12, 3, 2, "Hand", "Crop Seeds"),
    ("require selected seeds", 12, 0, 2, "Hand", "Dirt"),
    ("harvest with hoe", 16, 0, 13, "Hoe", "Crop Seeds"),
]:
    grid = [[0] * 8 for _ in range(8)]
    grid[3][3], grid[3][2], grid[3][4] = tile, above, below
    random.seed(713)
    handled, edits, consume, drops = module.farming_interaction(grid, 3, 3, tool, selected)
    cases.append(dict(name=name, tile=tile, above=above, below=below, tool=tool,
                      selected=selected, handled=handled, edits=edits,
                      consume=consume or "", drops=dict(drops)))
target = ROOT / "tests" / "python_farming_reference.json"
target.write_text(json.dumps(cases, indent=2))
print(f"Captured {len(cases)} cases from {source}")
