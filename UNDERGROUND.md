# Underground expansion

World height is now 1,440 blocks, up from 360. The original surface and upper terrain generation remain intact; additional caves, ores and liquids use an independent seeded generator below the old boundary.

## Exploration

- Root caverns and limestone halls below the surface.
- Sunken aquifers with finite water pockets.
- Prism caverns with blue, purple, green, amber and pink crystals.
- Fungal hollows with luminous native pixel-art mushrooms on suitable planets.
- Basalt depths with lava pockets.
- A molten underworld with a bottom lava sea, arched block bridges and low fortified halls. The old free-standing tall pillars are removed from new generation.

Seeded fortresses contain open entrances, stair flights, upper galleries, damaged battlements, torches and usable ore/crystal chests. Bridges, stairs and walls are real mineable stone/obsidian blocks rendered with the existing Aseprite artwork. Bridge piers connect to the bottom foundation. Existing worlds receive structures once, only in clear, untouched lava/air footprints; intact old pillars are removed, while modified pillars and detected builds are preserved. Saved mining and looted chests are not regenerated. `underworld_structures_version` and `underworld_forts` persist this migration and layout.

See the [fortress gameplay preview](tests/underworld_fortress.png). Run `tests/underworld_structures_check.gd` to verify seeded layouts, bridge continuity, entrances, fluid synchronization, legacy pillar removal, preservation of builds, and save/load behavior. `tests/underworld_structures_preview.gd` regenerates the image.

Crystals and fungi illuminate nearby terrain. Light attenuates through rock, and harvesting a luminous formation removes its light. Crystals respect the existing mining tiers; stone formations require a suitable pickaxe. These formations are passable, create collectible drops, and retain their harvested state in saves. Removing their support also removes them.

Stalagmites rise from floors, stalactites hang from ceilings, and damp ceilings emit falling droplets and impact splashes. Drips are cosmetic: they do not add unlimited water to caves. Actual pools use the existing water/lava transport, damage, cooling and obsidian reactions. Decorations use spatial buckets, terrain textures are cached, and lighting is calculated near the camera.

## Existing saves

Old 360-row worlds expand when visited during the loading screen. Their original tiles, buildings and partial liquid amounts are preserved. The extension runs once; subsequent loading preserves deep mining and construction. Unvisited old worlds may remain in the old format until opened. New decoration is added once per world, avoiding placed building blocks and requiring empty cave space and natural supports.

## Aseprite artwork

Sources are `assets/sprites/source/underground/cave_formations.aseprite` and `cave_tiles.aseprite`. Both contain editable layers and named frame tags. The native Aseprite design script creates twelve formation/effect frames and seven biome tile frames. Runtime PNGs are in `assets/sprites/underground/`.

Use `tools/design_underground_aseprite.lua`, `export_underground_aseprite.lua`, and `verify_underground_aseprite.lua` with Aseprite's batch `--script` and `--script-param root=...` options. The main artwork export and verification scripts include these assets. Verification compares all 20,224 exported pixels against their native sources.

## Verification and previews

- `tests/underground_check.gd`: all planet climates, deterministic deep generation, formations/colors, real mining and illumination, actual old-save migration, partial fluids, and save/load persistence.
- `tests/fluid_obsidian_check.gd`: fluid transport, cooling, rain, contact conversion, mining and saved fluid state; waits for loading to finish before checking restoration.
- `tests/ocean_loading_check.gd`: ocean preparation, legacy ocean repairs and preservation of excavations/storage.
- `tests/water_lighting_input_check.gd`: liquid conservation, darkness, rock occlusion, fog and held mining input.
- `tests/expedition_check.gd`: campaign crafting, combat and persistence.

Run checks with Godot `--headless --path . --script tests/<name>.gd`. Run `tests/underground_preview.gd` with the normal renderer to regenerate the [seven-biome overview](tests/underground_review.png) and [crystal gameplay view](tests/underground_crystals.png).
