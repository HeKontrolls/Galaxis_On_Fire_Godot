# Underground mining and flow update

## Continuous lava falls

Lava now transfers at most half of a cell's contents downward on each viscous tick, while retaining its existing 96-unit cap and slower 0.28-second tick. A descending parcel leaves a finite trail instead of repeatedly emptying a cell and creating a detached row below it. Total lava and transported cooling are conserved.

The renderer joins neighboring thin lava sections, connects falling flow to the receiving pool and matches a ledge reservoir to its adjoining stream. Connected falling columns share their horizontal boundaries and use the same body color, removing the narrow gaps and individually shaded ribbon edges. Water uses the same connected geometry at ledges; isolated streams retain their own width. It does not draw connectors through solid separators or invent fluid across empty passages. Water retains its own transport fraction and droplet rendering. The mesh uses the existing procedural fluid rendering path; no sprite was generated for this effect.

## Mining rhythm and power

Mining swings and recovery now share a 0.48-second cadence across tool materials. Tools transfer work into a block's saved damage progress rather than accelerating the entire animation. Pickaxe and shovel mining power uses the material table's multiplier times four. Hardness varies by material; stronger tools need fewer strikes on tougher blocks. Soft blocks can reach a one-hit ceiling. Axe damage retains its advantage on trees; shovels outperform pickaxes on soil. Pickaxes are still poor tree-cutting tools. Swords still cannot mine.

The seven existing pickaxe harvest levels, durability values and combat bonuses remain unchanged. Combat attacks retain their separate cadence. Tooltips and the HUD now show mining power instead of implying that the material multiplier speeds up the swing. Existing fractional mining progress remains compatible.

## Cave-wall ore

A separate background layer contains natural coal, copper, iron, gold, alien-crystal and diamond seams. These are mineral sprites, not periodic-table icons. The existing inventory representations remain unchanged. Deposits are clustered and seeded by depth, only in underground air/water cells, and never replace foreground terrain. Existing planets receive the layer once on opening.

Equip a Hammer or Mattock and left-click/hold to mine the visible wall seam within the normal four-block digging reach and with clear line of sight. Foreground blocks conceal seams until cleared. The Hammer has wall-mining power 8 and level 1 (coal/copper/iron); the Mattock has power 16 and level 2 (including gold/crystal/diamond). Both use the same 0.48-second swing. Each completed seam drops one matching ore item. Partial damage and harvested deposits persist across save/load; depleted seams do not regenerate. Cave crystals and plants retain their existing ordinary-tool interaction priority.

Both wall tools are craftable through a Workbench's inventory:

- Hammer: 4 Cobblestone, 2 Iron Ingots, 2 Sticks.
- Mattock: 4 Iron Ingots, 2 Sticks.

The Mattock uses a layered 32x40 Aseprite source and the same (16,32) gameplay grip as existing tools. Background mineral art has two layers, six ore tags, three variants per ore and 16x16 cells. Sources live in `assets/sprites/source/underground/`; PNGs and JSON metadata live in `assets/sprites/underground/`. Native authoring, export and verification scripts are `tools/design_background_ores_aseprite.lua`, `export_background_ores_aseprite.lua` and `verify_background_ores_aseprite.lua`; the main art workflows include them.

## More pools

Newly generated deep underground terrain makes 320 pool attempts instead of 85. Pools have varied widths, curved stone bottoms and depths of two to six blocks, with overlap rejection to avoid cutting a new drain through a previous basin. Retaining banks end at the fluid surface; the former five-block posts above either end are no longer generated. The checked seeds produced 270-273 pools. Temperate/tundra samples included 171-176 water pools and 94-102 lava pools; the volcanic sample contained 270 lava pools and no water pools. Lava favors basalt depths and volcanic planets; other deep regions receive water.

Existing pools receive a one-time cleanup of intact, recognizable generated upper posts when the planet opens. Edited columns, placed props, basin floors and stored fluid are preserved. Cave features supported by a removed post are retired, and vines revalidate their support. Repair versions persist with each pool so later player construction is not removed on another visit. Revisiting an older planet does not carve new basins through builds or refill drained lakes. Older legacy-size worlds receive the new pool layout only in their newly appended deep layers. Background ore, tool changes and lava-flow changes apply to existing worlds.

## Checks and preview

`tests/underground_mechanics_check.gd` checks mining cadence/power, harvest gates, continuous finite lava transport, adjoining stream geometry, wall targeting and obstruction, ore drops, partial/depleted save state, real Mattock crafting/equipping, foreground mining, new pool climate balance and idempotent background generation.

The native art verifier compares all 5,888 exported pixels with the 19 source frames. Mining-tier, shovel/furnace, held-tool and lava/obsidian regression checks cover the existing systems affected by the update.

[Underground gameplay preview](tests/underground_mechanics_preview.png) shows the real fluid renderer, the new wall ores and the held Mattock. It uses a controlled chamber to make the interactions visible.


`tests/fluid_edges_check.gd` checks new generation, old-post repair, preservation of edited posts/props, unsupported features, actual saved-world repair, later builds, fluid-volume conservation, closed-basin retention and runoff through an opened bank. It checks matching vertices and colors along connected flow boundaries for water and lava, including solid separators. `tests/fluid_edges_preview.gd` renders and samples the actual lava image across internal column borders to catch visible gaps or shading seams.

Updated views: [pool banks without tall posts](tests/pool_rims_preview.png) and [one joined lava flow](tests/joined_lava_preview.png).
