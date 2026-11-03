# Hanging vines

Vines grow along natural cliff edges and hang from cave roofs on forest, island and mixed-ocean planets, with sparser growth on tundra worlds. Three native Aseprite styles provide trailing ivy, heartleaf and muted cave creepers. Roots, leaf segments and tapering tips are drawn before foreground terrain and receive the same underground lighting as the rest of the world.

Placement and starting lengths are seeded. Vines grow one eight-pixel segment every thirty seconds until their individual limit, floor or water. Surface vines sway with the wind; underground vines remain sheltered. Passing through them bends the strands without affecting player collision. Click with a digging tool or your hand to cut a strand at that point and collect Alien Fiber. The remaining rooted part can regrow; cutting the root removes it permanently. Removing supporting terrain removes its vines, and placing blocks trims obstructed growth.

Saved worlds retain vine locations, lengths, removed roots and growth timing. Existing worlds receive vines once when loaded; generation does not modify terrain or buildings. Vines are anchored only to grass, dirt, stone and snow. There are at most 420 strands per planet; drawing is culled to the screen and digging validates only nearby vines.

Editable source: `assets/sprites/source/ecology/hanging_vines.aseprite` (two layers, three frames and three tags). Artwork is painted inside Aseprite by `tools/design_vines_aseprite.lua`; use `tools/export_vines_aseprite.lua` to export manual edits without repainting. `tools/verify_vines_aseprite.lua` compares all 1,152 exported pixels with the native source. The main artwork export and verification scripts include vines.

`tests/hanging_vines_check.gd` checks seeded generation, climate restrictions, ledges and ceilings, terrain preservation, growth, liquid/floor limits, actual mining, regrowth, duplicate-drop prevention, save/load, support removal and sheltered cave movement. The [review scene](tests/hanging_vines_review.png) shows both a trailing ledge vine and cave-ceiling strands in a controlled terrain fixture.
