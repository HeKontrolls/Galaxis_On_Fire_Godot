# Performance and farming update

Measured with Godot 4.7.2, OpenGL Compatibility, NVIDIA GeForce RTX 3070, 1280 x 720, VSync disabled and uncapped FPS. These are local development measurements, not a guarantee for other hardware.

| Scene | Initial 90-frame FPS | Updated 90-frame FPS | Updated 1,200-frame FPS | Updated longer-run p95 frame time |
| --- | ---: | ---: | ---: | ---: |
| Forest, clear | 23.0 | 321.8 | 324.5 | 4.89 ms |
| Forest, fog | 24.6 | 306.9 | 285.0 | 5.47 ms |
| Ocean, rain | 6.3 | 262.9 | 180.6 | 9.24 ms |

The scripts scroll 1.7 pixels per rendered frame after an 18-frame warmup. Game simulation uses elapsed frame time, so the slow initial build advances more simulation time during its 90 frames. Treat the initial measurements as diagnostic observations rather than an identical simulated-time comparison. Longer samples encounter more terrain and moving water. Planet generation and initial cache construction are excluded. Cached chunk construction, discovering a new tree canopy, and lighting rebuilds can still produce occasional frame-time spikes.

## Changes

- Cached front terrain and cave walls in 8 x 8 tile chunks, with local invalidation after edits and a bounded cache. Removed the invalid cave-background polygon.
- Cached ring geometry and fog meshes. Sunlight propagation starts at terrain/water boundaries; static light is reused while the player walks outdoors. Player and held-torch light still update underground.
- Bounded water simulation work and kept distant active cells queued. A slow frame no longer triggers multiple expensive catch-up ticks.
- Added rainfall accumulation, shallow surface puddles, runoff, and dry-weather evaporation. Rain lands on roofs. Only rain-derived water evaporates, including after it mixes with natural water. Rainwater provenance survives saves.
- Ported farming interactions from the Python source, including randomized growth, wet/dry soil, three corn stages, randomized corn/seed harvests, and the original crop silhouettes and soil tints. Nearby farm cells are indexed rather than scanned across the whole world each frame.
- Added colored periodic badges to world ores, pickups, and inventory icons: C 6, Cu 29, Fe 26, Au 79. Alien crystal stays purple and uses unknown symbol/number markers. Real element identifiers follow [IUPAC](https://iupac.org/what-we-do/periodic-table-of-elements/); colors are game material colors.

## Validation

All six checks passed:

- `grass_foliage_check.gd`: grass, canopy pixels, and saved falling leaves.
- `water_lighting_input_check.gd`: water conservation, generated climates, torch occlusion, held input, partial-water saves.
- `rain_farming_ore_check.gd`: 11 fixtures exported from the real Python farming function, faster watered growth, planted-row rain hydration, roof protection, puddle hydration/evaporation, separate rain/natural-water conservation, seed costs, harvesting, and save/load state.
- `grass_foliage_preview.gd`: rendered grass and transparent trunk pixels.
- `water_cave_fog_preview.gd`: rendered water, tree drops, cave darkness, and identical underground pixels with fog on/off.
- `rain_farming_ore_preview.gd`: rendered crops, soil, puddles, dry ground, and ore badges.

The controlled 90-second crop test produced 33 growth stages across dry crops and 105 across initially watered crops. The gameplay rules retain the Python 18 nearby random attempts per second, 4.5% dry / 18% watered growth chances, 5 percentage point outdoor rain bonus, and 45% soil-drying chance on successful watered growth. Harvests yield 2-4 Corn and 1-3 Crop Seeds. Rain hydration also handles planted rows and respects roofs.

Run `tools/export_farming_reference.py` to refresh the interaction fixtures from the neighboring Python project. Run `tools/profile_game.gd -- res://tests/fps_profile.json 1200` using Godot to repeat the longer benchmark.

Raw measurements: `tests/fps_before.json`, `tests/fps_final.json`, and `tests/fps_sustained.json`.

## Lava, snow, forest density, and gusts

The latest update adds viscous finite-volume lava, timed contact damage, dense forests, seeded wind gusts, and saved weather snow that melts into evaporating water. The forest content is much denser than the original benchmark scene, so these are current performance observations rather than a direct like-for-like comparison with the older sparse forest.

| Current scene | Average FPS | p95 frame time |
| --- | ---: | ---: |
| Dense forest, clear | 230.8 | 8.06 ms |
| Dense forest, fog | 203.2 | 8.92 ms |
| Ocean, rain | 180.1 | 9.85 ms |
| Forest, snowfall | 155.7 | 11.01 ms |
| Lava planet | 224.9 | 8.40 ms |

Same uncapped RTX 3070, OpenGL Compatibility, 1280 x 720 method as above, with 1,200 scrolling frames per scenario. Raw results are in `tests/fps_lava_snow_forest.json`.

Additional validation in `tests/lava_snow_forest_gust_check.gd` passed:

- Lava volume conservation, slower descent than water, lateral leveling, terrain displacement, water/lava separation, and old-save migration.
- Lava at the feet and in falling streams causes damage; 30, 120, and 300 FPS all leave the same 60 HP after 0.8 seconds of contact from 100 HP. God Mode and lethal-contact respawn work.
- Snow accumulates on ground and roofs, keeps covered ground clear, melts into tagged puddles, evaporates, responds to lava heat, and settles after digging. Permanent snow/ice terrain is preserved.
- A melting hillside above a 16-block-deep pit stayed at a maximum 48 rain-derived units per column, about 3.01 pixels of water, and dried completely.
- Forest samples increased from 10/14/9 to 144/140/142 trees. The one-time upgrade preserves existing terrain, construction, and crop plots and does not repeat on subsequent loads.
- Gusts have smooth transitions, calm intervals, repeatable seeded timing, and stronger storm bursts. Partial lava, temporary snow, forest upgrade state, and snowmelt protection survive saving.

The rendered sequence in `tests/lava_snow_forest_preview.gd` produces dense forest, snowy ground, melting/dried ground, slow lava flow, and visible lava-contact damage previews.

## Smooth fluids and obsidian

Water and lava now prioritize falling over spreading in midair. Fair simulation batches retain bottom-first order, preventing parcels from skipping multiple rows in one tick. Connected mesh surfaces, interpolated volumes, shared edges, and small droplets replace the old full-width tile highlights. Full submerged rows are combined into strips, and unchanged visible meshes are cached in world coordinates so camera scrolling stays smooth.

Direct water contact solidifies lava into obsidian and emits steam. Water used by the reaction retains correct natural/rain provenance accounting. Direct rain hits accumulate cooling, darken exposed lava, and eventually create an obsidian crust. A full cell needs eleven normal rain hits or six storm hits; small partial cells cool sooner. Roofs protect lava, cooling travels with flowing lava, and partial cooling gradually recovers when rain stops. Obsidian is solid, mineable with the pickaxe, reusable for building, and saved with the world. Reactions are bounded to 256 candidates and 32 new blocks per poll; steam is capped at 64 particles. Solidification waits when an intersecting player cannot escape safely.

`tests/fluid_obsidian_check.gd` passes contact in all four directions, diagonal and world-boundary cases, underground reactions, rain cooling through the actual precipitation collector, roof protection, cooling advection and reheating, player escape/deferred reactions, mining, placement, saved cooling, and older saves. The eight existing gameplay checks also pass, including finite-fluid conservation, prolonged storm flooding, snowmelt, farming, trees, and wind. `tests/fluid_obsidian_preview.gd` renders water/lava cascades, contact obsidian, partially cooled lava, and exposed obsidian beside roof-protected molten lava.

| Current scene | Average FPS | p95 frame time |
| --- | ---: | ---: |
| Dense forest, clear | 208.7 | 7.26 ms |
| Dense forest, fog | 204.7 | 7.34 ms |
| Ocean, rain | 170.5 | 8.79 ms |
| Forest, snowfall | 152.0 | 9.35 ms |
| Lava planet | 350.0 | 4.35 ms |

Same 1,200-frame scrolling method and RTX 3070 as above. Raw measurements: `tests/fps_smooth_fluids.json`. These are current local scene observations, not a controlled hardware-wide guarantee. Rendering still uses a finite tile-volume simulation underneath the smoothed geometry.

## Gameplay audio

Forty pre-generated WAVs supply footsteps, mining, swings, pickups, and a looping stereo rain bed. The runtime preloads the clips and reuses twelve effect players; synthesis happens only in `tools/generate_audio.py`. Physical pickups are briefly grouped, and footstep cadence follows actual grounded distance. Audio settings persist separately from saves. Rain fades with weather/orbit changes and becomes quieter and filtered beneath roofs and cave ceilings.

`tests/audio_check.gd` passes asset/sample checks, grounded movement and material selection, 30/60/144 FPS cadence (12 footsteps over three seconds at each rate), wall/jump/teleport silence, real mining and pickup hooks, swing recovery, modal suppression, weather/shelter transitions, volume/mute/save controls, and native effects/rain output meters. The five regression checks for tools, held input/lighting/water, food/farming, grass/foliage, and obsidian also pass. The rendered settings page is `tests/audio_settings_preview.png`; `tests/audio_showcase.wav` provides the sound sequence.

| Current scene with audio | Average FPS | p95 frame time |
| --- | ---: | ---: |
| Dense forest, clear | 234.0 | 7.96 ms |
| Dense forest, fog | 216.3 | 8.57 ms |
| Ocean, rain | 179.5 | 9.38 ms |
| Forest, snowfall | 162.1 | 10.61 ms |
| Lava planet | 356.7 | 5.69 ms |

Same 1,200-frame local scrolling method, Compatibility renderer, RTX 3070 and uncapped VSync-off setup. Raw results: `tests/fps_audio.json`. The current default seed is 12589134, so these observations are not a controlled comparison with older seeded scenes. Audio playback and rain ambience remain enabled during the run; the profile scrolls through terrain rather than exercising constant combat/mining.
