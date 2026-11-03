# Planet monsters

Eight native Aseprite documents contain 24 morphology/color variants and 144 animation frames. Each document retains three editable layers and six named animation tags: idle and walk for each morph. The 48x40 canvas has a bottom-center pivot at (24,36); bodies share a 24x18 gameplay collision box, with decorative tails and crests extending beyond it.

The surface creatures were completely redrawn to remain visible against plants, rocks and biome backgrounds. Large readable color patches, cream facial features and contrasting secondary materials replace the earlier camouflaged greens and grays. Each species has its own silhouette, not just a recolored body. Shadows use body colors; there is no exterior black stroke, glow outline, blur or semi-transparent sprite edge. The third layer adds only sparse two-pixel highlights so texture does not obscure the face or silhouette. Runtime rendering uses nearest-neighbor filtering and whole-pixel sprite origins.

| Planet | Creature | Visual identity | Behavior |
| --- | --- | --- | --- |
| Forest | Torchcrest | Amber biped, swept feather ears, cream throat and violet tail | Fast, longer detection range |
| Islands | Crown conch | Tall violet chambered shell, coral crawler and eye stalks | Slower, defends its immediate area |
| Ocean/continents | Coraljaw | Rose amphibian, branching gills and broad pale jaw | Quick surface hunter on exposed land |
| Desert | Veilrunner | Violet runner with a turquoise ribbed sail | Long detection range and faster pursuit |
| Lava | Kiln beetle | Ivory segmented carapace, forked horn and cyan vents | Heavy, slow, stronger contact damage |
| Barren | Hammerhorn | Plum body, oversized forearms and amber shovel head | Armored, slow, short detection range |
| Frozen ocean | Ruby tusker | Warm red quadruped with ivory brows and curled tusks | Pursues on exposed ice and land |
| Tundra | Plume strider | Teal running bird, peach wing fan and antler crown | Tougher, moderate pursuit speed |

Morphs vary palettes and features such as crests, horns and fins. Walking animates limbs and tails; idle frames blink. Existing asset filenames, canvas sizes, pivots, animation layout and saved family indices remain compatible. Existing worlds automatically display the new art, preserving creature health, deaths and genes. Flying creatures, slimes, cave wildlife and the expedition sentinel retain their separate artwork.

All artwork is painted inside Aseprite by `tools/design_monsters_aseprite.lua`, using `tools/monster_anatomy_aseprite.lua` and `tools/monster_materials_aseprite.lua`. This is an intentional regeneration script: it replaces native drawings. To export manual artwork changes without repainting, use `tools/export_monsters_aseprite.lua`. Both accept `--script-param root=D:/galaxy_game/Galaxis_On_Fire_Godot` through Aseprite's batch runner. Exports are eight 288x120 transparent PNG sheets and JSON animation metadata under `assets/sprites/monsters`.

`tools/verify_monsters_aseprite.lua` checks all 276,480 exported pixels against the native timeline, binary alpha, transparent canvas borders, layer counts, tags and absence of the former exterior black ink band. The main artwork exporter and verifier include this set.

The runtime selects a family from planet climate, then deterministically chooses a dominant planet morph and individual appearance, animation phase, speed, patrol radius and alert distance from the planet seed and spawn identity. These are authored variants rather than unbounded generated anatomy. Creatures patrol, pursue visible nearby players, stop at solid walls or steep drops, flash on hits, take tool damage and drop Alien Fiber when defeated. New spawns avoid the landing area and require clear, exposed surface support. Defeated creatures stay defeated.

See the [family review](../../../../tests/planet_monsters_review.png) and [gameplay view](../../../../tests/planet_monsters_gameplay.png). `tests/planet_monsters_check.gd` checks all climates, seed determinism, saved genes, legacy deaths, actual movement, contact damage and wall collisions; `tests/expedition_check.gd` covers quest combat and save restoration.
