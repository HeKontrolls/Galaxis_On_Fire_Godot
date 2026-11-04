# Magic, equipment and mastery

Magic is a craftable combat and exploration path for the Godot game. All equipment, spell bolts, lightning, ward/healing auras, status icons and the light orb were authored in Aseprite: 18 layered sources, 63 frames, with idle/cast/loop tags and exported PNG/JSON metadata.

The [alchemy and spellcrafting expansion](ALCHEMY_AND_SPELLCRAFT.md) adds an Alchemy Desk, cauldron, custom named focuses, a 20-node skill tree and Necromancy. K now opens the tree, original spell guide and player creation library.

## Playing

Craft equipment at a placed **Workbench** using its own ingredient slots. Put a wand, staff or book in your hotbar, select it, aim with the mouse and **left-click**. Holding left-click repeats when its recovery and mana allow. These items cannot mine, harvest crops or place terrain. Casting does not consume the equipment or require arrow ammunition.

**K** opens the draggable, closable Arcane Field Guide next to the backpack. It shows owned equipment, every spell's cost and recovery, and all five mastery schools. Right-click a held focus also opens the guide. **Esc/K/X** closes it. **F3 > Magic > Grant Magic Test Kit** grants all eight focuses plus eight Mana Tonics for testing. New games begin with no equipment.

Mana starts at **100**, regenerates at **6 per second** after two seconds without a successful cast, and has its own HUD below the existing shortcuts. Failed casts do not spend mana. Each item has its own recovery; a short shared 0.25-second recovery prevents instant bursts by swapping hotbar slots. Pause, menus, inventory/station windows, dialogue and developer controls stop magic simulation. Timers use active gameplay time, with no real-world catch-up.

Select a **Mana Tonic** and left/right-click to restore up to 50 MP, consuming one tonic. There is an eight-second tonic recovery. Full mana and cooldowns reject drinking without consuming an item.

## Equipment

Values below are base values at school rank 1.

| Equipment | School | MP | Recovery | Effect | Workbench ingredients |
|---|---|---|---|---|---|
| Ember Wand | Destruction | 7 | 0.45s | 15 impact damage + 6 burn damage each second for 3s | Stick 4, Copper Ingot 1, Crystal 1 |
| Frost Wand | Destruction | 10 | 0.65s | 18 damage; enemy movement/state simulation slowed to 55% for 3s | Stick 4, Glacial Ice 4, Crystal 2 |
| Storm Staff | Destruction | 24 | 1.35s | 28-damage lightning, chaining to two more enemies with 25% damage loss per bounce | Planks 8, Copper Ingot 4, Crystal 3 |
| Crystal Staff | Destruction | 14 | 0.80s | 25 damage; pierces two different enemies | Planks 8, Iron Ingot 3, Crystal 4 |
| Mending Tome | Restoration | 25 | 5s | Restores up to 24 HP; refuses to cast at full health | Alien Fiber 6, Wildflower 4, Crystal 2 |
| Ward Book | Warding | 25 | 10s | Absorbs 40 creature-contact damage for up to 8s | Alien Fiber 6, Iron Ingot 2, Crystal 2 |
| Greater Ward Book | Warding | 40 | 16s | Absorbs 80 creature-contact damage for up to 10s | Ward Book 1, Gold Ingot 3, Crystal 5 |
| Lumen Tome | Illumination | 12 | 1s | Following cave light for 60s | Alien Fiber 4, Crystal 2, Torch 4 |
| Mana Tonic | Consumable | - | 8s | Restores up to 50 MP | Crystal 1, Corn 2 |

Crystals are the alien crystal resource already mined underground. Each recipe produces one reusable focus or one tonic. Greater Ward consumes the lesser book as an upgrade.

Projectile spells collide with terrain and closed doors. The muzzle cannot put a shot through an adjacent wall. Ember bolts extinguish in water; submerging a burning enemy also extinguishes the burn. New hits refresh burn/slow duration; they do not stack unlimited copies. Lightning requires the first aimed enemy within 16 blocks of the caster, then each bounce within seven blocks of the previous enemy. Every segment requires a clear path. No target means no lightning cost.

Wards work against ground, flying and cave creatures. Damage beyond the remaining barrier reaches health. Wards neither stack nor prevent lava damage, and switching equipment does not remove an active barrier. A weaker/full replacement is rejected. Breaking a ward clears it; its book still needs to finish its recovery. Lumen follows the player independently of held torches, adds no torch warmth, and does not act as a permanent crop lamp. Its duration can be refreshed only in its last ten seconds; only a fresh light earns mastery.

## Skills

Five schools progress through ranks **1-5**, at **0, 30, 90, 180, 300 cumulative XP**. Each rank above 1 adds **5 maximum mana** and **8% to that school's principal effect**: direct Destruction damage, Restoration healing, Warding absorption, or Illumination duration. Burn ticks remain 6 damage per second. Maximum total mana is 200 when all five schools reach rank 5. A rank increase raises capacity; it does not refill the mana pool.

- Destruction: XP from actual damage dealt by successful direct hits, capped at 10 XP per hit. Empty shots and burn ticks do not give extra XP.
- Restoration: XP from health actually restored.
- Warding: XP from damage actually absorbed.
- Illumination: 8 XP from a fresh Lumen cast, with no XP from refresh spam.

Mana, mastery XP, individual recoveries, remaining barrier strength/duration and light duration are saved on the character. Older saves receive safe defaults. Travel clears transient bolts and lightning, while retaining character resources and timed buffs. Creature burn/slow timers are saved with that planet's creatures and resume when it is active. Respawning clears the ward and projectiles and restores mana; starting a new game resets all magic progression and buffs.

## References and design choices

Online research informed the equipment families and distinct roles rather than copying another game's damage tables or artwork. Terraria groups magic equipment into projectile wands/staffs and spell tomes, with fire and frost wand examples: [magic weapons](https://terraria.fandom.com/wiki/Magic_weapons), [Wand of Sparking](https://terraria.fandom.com/wiki/Wand_of_Sparking). ArenaNet describes elemental attunements with offensive and support roles: [Guild Wars 2 Elementalist](https://www.guildwars2.com/en/the-game/professions/elementalist/). These ideas informed Galaxis's elemental attacks, restoration, protection and exploration magic. The damage values, progression, wards and recipes above are original game rules.

## Artwork and validation

Editable sources: `assets/sprites/source/magic/*.aseprite`. Runtime sheets and metadata: `assets/sprites/magic/`. Use `tools/design_magic_aseprite.lua`, `export_magic_aseprite.lua` and `verify_magic_aseprite.lua` through Aseprite's batch runner. Magic is included in the main art export/verification scripts.

`tests/magic_system_check.gd` covers hotbar input, costs/recovery, mana regeneration, all spell behaviors, collisions, water/fire interactions, chain visibility, kills/loot, progression, cave light, ward/lava rules, crafting, guide controls, older saves and new-game reset. `tests/magic_system_preview.gd` renders the [art review](tests/magic_art_review.png), [casting](tests/magic_gameplay.png), [lightning](tests/magic_chain_lightning.png) and [skill guide](tests/magic_skill_guide.png).
