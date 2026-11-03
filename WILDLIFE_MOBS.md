# Slimes and cave inhabitants

Nine native pixel-art families supplement the existing planet monsters and surface flyers:

| Family | Habitat | Behavior | Drop |
| --- | --- | --- | --- |
| Meadow slime | Forest/grassland surfaces, root and fungal caverns | Squashes, hops and rests | Alien Fiber |
| Brine slime | Island/continental surfaces and aquifers | Hopping gel with internal bubbles | Alien Fiber |
| Dune slime | Desert and barren surfaces | Sand-filled hopping gel | Alien Fiber |
| Rime slime | Frozen/tundra surfaces | Ice-crowned hopping gel | Alien Fiber |
| Cinder slime | Hot surfaces, basalt and molten caves | Faster alerted hops | Obsidian |
| Prism slime | Limestone/prism caverns | Crystal-crowned hopping gel | Crystal |
| Cave scarab | Underground, including fortresses | Patrol, warning pause, charge, recovery | Stone |
| Pale scuttler | Underground, including fortresses | Warning pause and a leaping rush | Alien Fiber |
| Cave screecher | Underground air pockets | Warning, fixed-target dive, recovery | Alien Fiber |

Slimes have separate idle, squash, rising, falling and landing poses. Insects animate their legs; screechers animate their wings. All families have two seeded visual variants. A material-colored perimeter replaces black external outlines. All sprite pixels have binary transparency and use the existing nearest-neighbor rendering.

## Population and gameplay

`scripts/wildlife_mobs.gd` adds up to sixteen surface slimes, thirty-two inhabitants per depth band across six underground bands, and inhabitants in available fortress halls. The reference seeds produce 218 additional creatures per world. Actual placement requires clear terrain/liquid collision bounds; surface spawns avoid the landing area. The expedition crash site is prepared before wildlife so new cave inhabitants cannot prevent safe pod placement.

Population uses independent deterministic RNG and never edits terrain. Caves choose families from their underground biome. Local AI respects walls, ceilings and fluid barriers using motion substeps. Ground creatures fall when their support is removed. New AI pauses far above/below the player, and drawing culls creatures outside the viewport.

Slimes damage during hops; scarabs and scuttlers damage during their rush. Windups are harmless, marked with an amber warning. Screechers reuse the established flyer dive collision and warning system. Player damage cooldown, invulnerability, swords, hit flashes, knockback and item pickup remain shared with the existing combat system.

New and existing worlds receive this population once, tracked by `wildlife_version`. Creature health, deaths, movement state, variants and positions persist through the existing creature save data. Reloading does not replenish defeated creatures. Existing creatures and the quest sentinel retain their behavior.

## Artwork and verification

All artwork was authored using native Aseprite scripting. Nine editable sources are `assets/sprites/source/monsters/wildlife_0.aseprite` through `wildlife_8.aseprite`. Each has three named layers, sixteen frames and animation tags for both morphs. Runtime 384×80 sheets and JSON frame/pivot metadata are under `assets/sprites/monsters/`.

- `tools/design_wildlife_aseprite.lua`: native anatomy, palettes, clustered texture and animation poses.
- `tools/export_wildlife_aseprite.lua`: sheet and metadata export, included in the main artwork export workflow.
- `tools/verify_wildlife_aseprite.lua`: native/export equality for 276,480 pixels, layer/frame/tag structure, transparent borders, binary alpha and absence of a black external stroke.
- `tests/wildlife_mobs_check.gd`: all eight planet climates, all nine families, depth coverage, collision-safe deterministic placement, unchanged terrain, idempotent migration, save/death persistence, warning/attack behavior, damage cooldown, invulnerability, walls/ceilings and actual sword/loot integration.
- `tests/wildlife_mobs_preview.gd`: [family and pose review](tests/wildlife_mobs_review.png) and [fortress gameplay view](tests/wildlife_mobs_gameplay.png). The gameplay view positions examples together for inspection; ordinary populations are distributed throughout the world.

Run the gameplay check with Godot `--headless --path . --script tests/wildlife_mobs_check.gd`; run previews with the normal renderer. Run native artwork scripts with Aseprite `--batch --script-param root=<project> --script <script-path>`.
