# Bows, crossbows and arrows

Four ranged weapons and four ammunition types join the existing melee tools. All new art was authored in Aseprite: layered sources, three bow/reload poses per weapon, flight sprites and separate inventory bundles.

## Controls

- Put a bow or crossbow in the hotbar and select it. Arrows can stay in the backpack.
- **Bow:** aim with the mouse, hold left-click to draw, then release to fire. A short tap fires a weaker, slower arrow. The bar below the player shows draw strength.
- **Crossbow:** left-click to fire immediately; its reload takes 1.1 seconds. Holding left-click repeats after each reload.
- **Right-click while holding a weapon:** cycle owned arrow types. The hotbar caption shows the current type and count. Empty ammunition automatically falls back to another owned type. An arrow placed in the hotbar can also be selected with right-click.
- Changing tools, opening a window, losing focus, or entering developer controls cancels a drawn shot without spending ammunition.

Each successful shot consumes exactly one arrow. Bows and crossbows cannot mine terrain or harvest crops. Right-clicking them selects ammunition instead of placing blocks.

## Weapons

| Weapon | Full-draw base damage | Full draw / reload | Workbench ingredients |
|---|---|---|---|
| Wood Bow | 14 | 0.70s draw, 0.24s recovery | 6 Planks + 4 Stick + 2 Alien Fiber |
| Copper Bow | 20 | 0.65s draw, 0.24s recovery | Wood Bow + 3 Copper Ingot + 2 Alien Fiber |
| Iron Bow | 28 | 0.60s draw, 0.24s recovery | Copper Bow + 4 Iron Ingot + 3 Alien Fiber |
| Iron Crossbow | 36 | 1.10s reload | 6 Iron Ingot + 8 Planks + 3 Alien Fiber |

Alien Fiber comes from defeated creatures. Use **F** to open a placed workbench, put the materials in its stored input slots, select the weapon recipe, and take the crafted weapon from its output. The metal bow recipes consume the previous bow as an upgrade.

## Ammunition

| Ammunition | Added damage | Enemies per shot | Recipe |
|---|---|---|---|
| Stone Arrow | +0 | 1 | 4 Stick + 2 Stone -> 16 arrows; Basic crafting or workbench |
| Copper Arrow | +3 | 1 | 4 Stick + 1 Copper Ingot -> 16 arrows; workbench |
| Iron Arrow | +6 | 1 | 4 Stick + 1 Iron Ingot -> 16 arrows; workbench |
| Crystal Arrow | +9 | 2 | 8 Iron Arrow + 1 Crystal -> 8 arrows; workbench |

Quick bow shots deal 45% of the weapon's base damage; a full draw deals 100%, plus the arrow bonus. Gravity bends trajectories, wind gently affects flight, water slows arrows, and lava consumes them. Arrows hit surface monsters, flyers, cave wildlife and the quest sentinel. Terrain and closed doors stop arrows, including when the bow is pressed against a wall. Ordinary arrows that miss and strike terrain become physical pickups; arrows that hit enemies are spent. Crystal tips pierce two distinct enemies and shatter against terrain.

Projectile updates use a fixed simulation step and swept collision checks. Shots expire after five seconds, with a 64-projectile limit. The existing combat loot and hit-flash behavior also apply to ranged kills.

New games keep empty starting inventories. Developer **Tools > Grant Starter Tools** now includes a Wood Bow and 64 Stone Arrows. The give command recognizes all eight items. Weapons, arrow stacks, quiver choice, equipped hotbar item and reload cooldown survive saves. Old saves default to Stone Arrows. Draw state and arrows still in flight are transient and reset on travel/load.

## Editable artwork and validation

`assets/sprites/source/weapons/{bows,arrows,arrow_icons}.aseprite` holds the three-layer native artwork and named tags. PNG sheets and JSON frame metadata live in `assets/sprites/weapons/`. Regular Aseprite export/verification includes these assets.

- `tests/ranged_weapons_check.gd`: real mouse press/hold/release, ammo counts and switching, cancelling shots, ranged-only tools, crossbow reload, enemy types, piercing, solid terrain/doors, muzzle obstruction, recovery, water/lava, frame rates, crafting, legacy and current saves.
- `tools/verify_weapons_aseprite.lua`: exact native-to-export pixels, frames, layers, tags and binary alpha.
- `tests/ranged_weapons_preview.gd`: [art review](tests/ranged_weapons_art.png), [aiming](tests/ranged_weapons_aiming.png), [firing](tests/ranged_weapons_firing.png), [backpack](tests/ranged_weapons_backpack.png).
