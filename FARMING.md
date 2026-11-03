# Farming and food

The Godot rebuild now has a renewable crop loop: forage seeds, prepare a field, plant, water or irrigate, harvest, save planting stock, cook meals, and eat to restore health.

## Controls and starting a farm

New games still start with empty bags and hotbars. R0-VR awards a hoe, watering can, corn seeds, and a small sample of the other four crops when the workshop objective is complete. Seeds can also be gathered from wild plants.

1. Clear rocks and decorative plants from a patch of grass or dirt.
2. Equip the hoe in the hotbar and left-click the ground to till it.
3. Select a planting item in the hotbar and right-click the soil or the empty space just above it. Each plant uses one item. Leave three blocks of clear height.
4. Equip the watering can and left-click the soil or crop. The existing pouring animation plays, and even already-wet soil has its moisture refreshed.
5. Point at a plant to see its species, growth, soil state, and estimated time remaining. Click a ripe crop to harvest produce and 1?3 planting items. Young plants can be uprooted with a hoe for one seed. Removing their soil also returns one seed.
6. Put produce and fuel into a furnace using **F**. Take the cooked meal from its output. Right-click food in the hotbar or backpack to eat, or press **R** for quick eating.

Farming actions use the same four-block reach as digging. Crops are passable. They sway with the wind and use native Aseprite artwork at each of three growth stages.

## Crops

| Crop | Planting item | Full-water daylight growth | Wild seed sources |
|---|---|---|---|
| Corn | Crop Seeds | 2:30 | Meadow grass, reeds |
| Carrot | Carrot Seeds | 1:30 | Wildflowers |
| Potato | Seed Potato | 1:50 | Ferns, broadleaf plants |
| Tomato | Tomato Seeds | 2:20 | Berry shrubs, leafy bushes |
| Wheat | Wheat Seeds | 2:00 | Dry grass, tumbleweed |

Each harvest yields 2?4 produce. At a workbench, one harvested crop makes three planting items, or two seed potatoes. Player-planted decorative flora does not generate extra seeds when recovered.

## Water, light, and travel

Watered growth is four times faster than dry growth. Watering fills soil moisture; without rain or irrigation it drops below the wet threshold after about 2:24 and fully dries after 3:00. Exposed rain refreshes moisture; roofs keep it off the soil. A water channel with at least 48/255 fill irrigates soil within four blocks horizontally at soil height or one block above. Stone and building blocks stop irrigation through the row. Irrigation does not consume the channel.

Outdoor crops grow during daylight. Desert growth is 65% of the normal rate. Exposed crops on lava, barren, and frozen-ocean planets cannot grow; use a roof and a nearby torch or lit fireplace within six blocks, with a clear light path. Covered crops on any planet require this light and can then grow through the night.

All planted fields update regardless of distance from the player. Visited planets continue growing during active planetary play elsewhere, using their stored irrigation and lighting; unobserved rain is not simulated. Growth pauses with paused gameplay, open inventory/station/crafting screens, developer mode, and menus. There is no real-world offline catch-up. Crop species, partial growth, moisture, and harvest RNG survive saves. Existing corn saves migrate automatically.

## Food and cooking

| Meal | Furnace inputs | Cooking after 5-second warm-up | Healing |
|---|---|---|---|
| Roasted Corn | Corn + Wood | 6s | 30 HP |
| Baked Potato | Potato + Wood | 8s | 25 HP |
| Tomato Soup | 2 Tomato + Wood | 10s | 35 HP |
| Bread | 3 Wheat + Wood | 10s | 30 HP |
| Vegetable Stew | Carrot + Potato + Tomato + Wood | 14s | 50 HP |

Fuel belongs in the furnace's fuel slot; ingredients and output remain stored in that station. A complete stew recipe takes priority over cooking its ingredients separately. A warm furnace can process following meals without another full warm-up. Corn, carrot, potato, and tomato can also be eaten raw for 15, 8, 5, and 10 HP. Wheat is a cooking ingredient. Eating has a three-second cooldown and does not waste food at full health.

## Artwork and checks

Editable layered sources: `assets/sprites/source/farming/{crops,farm_items,soil}.aseprite`. Runtime sheets and frame/tag metadata: `assets/sprites/farming/`. The regular Aseprite export and verification scripts include this set.

- `tests/farming_complete_check.gd`: five crops, actual hotbar actions, watering mature crops, uprooting/support loss, irrigation barriers, climate/light, frame-independent growth, foraging, station recipes, timed cooking, eating, travel, saves.
- `tests/food_farming_check.gd`: backpack/hotbar food controls, cooldowns, full health, trash, legacy saves.
- `tests/rain_farming_ore_check.gd`: original Python interactions (with Godot moisture refresh), rain, roofs, evaporation, wet/dry growth and saved state.
- `tests/farming_food_preview.gd`: field, backpack, and live furnace screenshots.

Review images: [field and crop stages](tests/farming_food_eating_preview.png), [backpack](tests/farming_food_backpack_preview.png), [cooking stew](tests/farming_food_cooking_preview.png).
