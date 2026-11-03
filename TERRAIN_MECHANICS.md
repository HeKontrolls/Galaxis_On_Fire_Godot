# Loose terrain and water pressure

Sand and gravel now fall when their support is removed. Each tile becomes a continuous falling body, accelerates under gravity, slows in water, and settles back into one ordinary mineable block. Columns cascade from the bottom and preserve material order. Stone, dirt and constructed blocks retain their existing support rules.

Falling material pauses when it encounters the player, robot or a mob, then continues when the actor moves away. It does not crush or entomb actors. Chests, benches, trunks, crops and placed torches act as support rather than being overwritten. If a player builds into a moving piece, that piece becomes one matching pickup instead of replacing the build. Water and lava are displaced into connected available space before a piece settles; if no space is available, settling waits. Moving bodies do not displace fluid until they settle.

Gravel is tile 45, with four 16x16 pebble variants authored in native Aseprite. It can be mined, collected, assigned to the hotbar and placed; shovels use the soil progression and outperform pickaxes. New planets receive seeded underground gravel pockets using an independent random stream. Existing saved terrain is not repainted with new deposits. Existing sand gains gravity when the area is visited or edited. You can also obtain Gravel through the developer give command.

Water pressure transmits through connected, full water cells. A higher reservoir can push water up a lower outlet or return shaft, including around bends in a U-shaped passage. It cannot cross a solid wall, cross an air gap as a siphon, or raise water above its supplying surface. Partial surface levels also equalize. Transfers move existing water and its rainwater fraction; they do not create water or convert natural water into evaporating rainwater. Lava keeps its slower gravity flow and does not use the new water-pressure solver.

This is a bounded local gameplay approximation of hydrostatic pressure, not a whole-planet fluid solve: two path searches of up to 512 connected cells per water tick, within the active fluid region. Large or distant networks settle as the player visits them; paths exceeding the search bounds are not solved globally. Unproductive pressure sources retry later, and the strongest available head is prioritized so small nearby differences do not starve lower outlets.

Loose terrain uses at most 64 moving pieces, starts at most eight per scan interval, scans only 768 local cells per interval, and sweeps motion in steps of at most two pixels. Pending edits wake neighboring sand/gravel; a gradual local scan also finds unsupported blocks in older saves. World changes invalidate existing terrain, fluid and lighting caches. Moving pieces and velocities persist per planet in saves and resume when revisited. Existing saves without the field load normally. No new rain supply or evaporation changes are included.

## Artwork

- Editable source: `assets/sprites/source/terrain/gravel.aseprite` (two layers, four frames, `terrain_variants` tag).
- Runtime sheet and metadata: `assets/sprites/terrain/gravel.png` and `gravel.json`.
- Native Aseprite author/export/verify scripts: `tools/design_gravel_aseprite.lua`, `export_gravel_aseprite.lua`, `verify_gravel_aseprite.lua`.
- The main artwork exporter and verifier include gravel. Falling sand reuses the existing sand terrain artwork.

## Validation

`tests/terrain_mechanics_check.gd` covers supported/unsupported columns at 30/60/120 FPS, mixed sand/gravel order, player obstruction, submerged settling with natural/rainwater conservation, chest protection, actual shovel mining and gravel drops, actual mid-fall save/load, deterministic new-world deposits, U-shaped pressure flow, solid-wall isolation, broad chambers and partial surface equalization. `water_lighting_input_check.gd` and `fluid_obsidian_check.gd` cover existing fluid and lava/obsidian behavior.

[Gameplay preview](tests/terrain_mechanics_preview.png) is rendered by `tests/terrain_mechanics_preview.gd` using actual terrain, moving pieces and simulated connected reservoirs.

A 300-frame-per-scene local smoke profile with VSync disabled on the RTX 3070 averaged 149.5 FPS (clear forest), 145.7 (fog), 99.4 (rainy ocean), 107.0 (snow) and 199.7 (lava). These are a short current-build snapshot, not a controlled before/after comparison or a guarantee for other hardware. The fluid-update section averaged 0.10–0.30 ms per frame, with a 4.41 ms maximum in the rain scenario. Raw results: [terrain mechanics profile](tests/terrain_mechanics_profile.json). Existing rain-flooding checks also passed a 600-second storm without replenishing unlimited rainwater.
