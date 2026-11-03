"""Render the original debug panel directly from its Python draw block."""
import ast
import json
import os
import sys
from pathlib import Path

os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
sys.dont_write_bytecode = True
project = Path(__file__).resolve().parents[1]
original = project.parent / "Galaxis_On_Fire"
sys.path.insert(0, str(original))

import pygame
from systems.main_helpers import BASE_CRAFT_RECIPES, WORKBENCH_RECIPES, FURNACE_RECIPES
from tiles import NAME_TO_ID, TILE_TYPES

pygame.init()
names = set(NAME_TO_ID)
names.update(info["name"] for info in TILE_TYPES.values() if info.get("name"))
names.update(("Torch", "Pickaxe", "Sword", "Axe", "Hammer", "all starter", "alltools", "tools", "starter"))
for recipe in BASE_CRAFT_RECIPES + WORKBENCH_RECIPES + FURNACE_RECIPES:
    name = str(recipe.get("out", "")).strip()
    if name and not name.lower().startswith("unlock "):
        names.add(name)
catalog = sorted(names, key=lambda name: (name.lower() in ("all starter", "alltools", "tools", "starter"), name.lower()))
(project / "assets" / "data").mkdir(exist_ok=True)
(project / "assets" / "data" / "dev_item_catalog.json").write_text(json.dumps(catalog, indent=2), encoding="utf-8")

source = (original / "systems" / "planet_render.py").read_text(encoding="utf-8-sig")
tree = ast.parse(source)
block = next(node for node in ast.walk(tree) if isinstance(node, ast.If) and isinstance(node.test, ast.Name) and node.test.id == "debug_panel_open")
draw = compile(ast.Module(body=block.body, type_ignores=[]), str(original / "systems" / "planet_render.py"), "exec")
for tab in ("weather", "tools", "farming", "power", "seasons"):
    screen = pygame.Surface((1280, 720))
    env = {
        "pygame": pygame, "screen": screen, "WHITE": (255, 255, 255), "YELLOW": (255, 220, 80), "GRAY": (80, 80, 80),
        "debug_panel_rect": pygame.Rect(20, 80, 560, 390), "mouse_pos": (900, 600),
        "font_small": pygame.font.SysFont("consolas", 18), "debug_active_tab": tab,
        "draw_text": lambda surface, text, x, y, font, color: surface.blit(font.render(text, True, color), (x, y)),
        "day_length": 480.0, "max_night_dark": 0.40, "current_weather": "sunny", "current_biome": "forest",
        "weather_timer": 80.0, "storm_chance": 0.08 / 1.008, "admin_god_mode": False, "admin_free_flight": False,
        "debug_command_input": "", "debug_give_suggestions": (), "text_cursor_on": False,
        "power_state": {}, "calendar_info": {"season": "Bloomrise", "date_label": "Y1 Bloomrise 1"},
        "debug_command_feedback": "Select a debug tab.", "debug_command_feedback_timer": 3.0,
    }
    exec(draw, env)
    pygame.image.save(screen.subsurface((20, 80, 560, 390)), str(project / "tests" / f"python_dev_{tab}_reference.png"))
print(f"Copied {len(catalog)} original item names and rendered five Python developer references.")
pygame.quit()
