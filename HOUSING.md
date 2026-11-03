# Housing and furnishings

Six house pieces are craftable through the Workbench's input/output inventory and can be assigned to any hotbar slot. Select a piece and right-click to place it. Placement uses the existing building reach; mining uses the four-block digging reach and clear line of sight. All artwork was authored and exported in native Aseprite at the game's 16-pixel block scale.

| Piece | Size | Workbench recipe | Behavior |
| --- | --- | --- | --- |
| Wooden Chair | 1 x 2 blocks | 4 Planks, 2 Sticks | Passable decoration; faces the placement direction |
| Wooden Table | 3 x 2 blocks | 8 Planks, 4 Sticks | Passable decoration with detailed tabletop and braced legs |
| Wooden Ladder x4 | One block per segment | 2 Planks, 4 Sticks | W/Up climbs, S/Down descends, Space jumps off; horizontal movement exits |
| Fireplace | 3 x 3 blocks | 12 Cobblestone, 4 Wood, 1 Torch | Animated fire, warm room lighting, F to light/extinguish |
| Wooden Wall x4 | One background block | 1 Plank | Background wall for interiors; passable and independent of foreground terrain |
| Wooden Door | 1 x 3 blocks | 6 Planks, 2 Sticks | F opens/closes; a closed door blocks actors and liquid |

Chairs and tables currently serve as decorations. Chairs, tables and fireplaces require solid support across their width; removing a supporting block returns the whole furnishing as one pickup. They do not block walking or fluid flow. Placements reject overlaps and occupied terrain, and station placement checks furniture footprints. Mine a furnishing to recover it; the existing tool damage and swing rules apply. Background walls are recovered with a Hammer or Mattock after foreground pieces at that location are cleared.

Ladders initially attach to solid terrain, another ladder or a placed wooden background wall. Connected ladder segments render seamless rails. Climbing holds position without input, respects solid ceilings and supports jumping or moving away. Ladders remain placed when an original terrain anchor is removed, matching the game's persistent building behavior.

Fireplaces start lit when dry and use the same unlimited-burn convention as placed torches. Water or lava entering the hearth extinguishes it. A wet fireplace cannot be relit until it dries. F prioritizes a fireplace under the pointer, so a nearby workbench does not capture its interaction. The on-screen hint and inventory tooltips explain the controls. Cooking and fuel storage are not part of this first decorative set.

Wooden background walls can be placed behind foreground terrain and furnishings. They replace the natural background visually and hide natural wall ore until removed. They do not make solid blocks or act as a roof; construct a foreground roof for shelter from rain. Removing a foreground block preserves its wooden backing. Wall textures use the existing terrain chunk cache.

Furniture locations, orientation, partial mining work, fireplace on/off state and background walls persist per planet. Existing saves receive empty furnishing/background layers automatically. Lighting sources, collision indexes and climb state are rebuilt on load; players do not resume attached to a ladder.

Doors are placed closed in a clear three-block-high opening with a solid floor. Closed door segments use ordinary solid terrain collision, so player/mob movement, line of sight, fluid flow and lighting respond to them. Open doors clear the passage. F prioritizes the door under the pointer, even beside another station or a fireplace. Closing is rejected while the player, robot, a mob or a nearby small critter occupies the doorway. Water/lava must have enough connected free space to be displaced before closing; volume and rainwater/cooling tags are conserved. Mining any door segment or removing its floor recovers one complete door and clears all collision segments. Open/closed state and partial mining progress persist in saves.

## Artwork

Layered sources: `assets/sprites/source/housing/`. Runtime PNG sheets and JSON metadata: `assets/sprites/housing/`. The sources have three named layers and animation/variant tags. The door uses a 32x48 canvas, a one-by-three-block footprint, an (8,48) pivot and four closed/turning/open poses. Native closing tags play in reverse. Door author/export/verify scripts are `tools/design_door_aseprite.lua`, `export_door_aseprite.lua` and `verify_door_aseprite.lua`. The fireplace has an unlit frame plus four burning frames; wooden walls have four plank variants. Native scripts are `tools/design_housing_aseprite.lua`, `export_housing_aseprite.lua` and `verify_housing_aseprite.lua`, and are included in the main art export/verification workflow.

## Validation

`tests/housing_check.gd` covers actual hotbar placement and inventory spending, unsupported/overlapping placement, walking through furniture, full furniture recovery, separate foreground/background editing, Hammer wall recovery, ladder ascent/hold/descent/jump/ceilings at 30/60/120 FPS, actual warm lighting, F priority beside stations, water extinguishing, Workbench crafting of all five recipes and actual save/load. The housing and door native verifiers compare 20,992 pixels across 16 source frames with their exports. `tests/doors_check.gd` checks actual placement/crafting/F interaction, player and creature collision, occupied-doorway rejection, open/closed and damage saves, complete mining/support recovery, fluid displacement/tag conservation and rejection of closing a sealed flooded doorway.

[Closed-door house](tests/housing_gameplay.png), [open doorway](tests/doors_open.png) and [Aseprite art review](tests/housing_art_review.png) are generated by `tests/housing_preview.gd`.

## Git

The active Godot project now has its own local Git history with a pre-feature baseline and a housing feature commit. See [version-control instructions](VERSION_CONTROL.md). The original Python game keeps its existing separate repository.
