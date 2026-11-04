# Alchemy, player-made magic and necromancy

The magic system now supports **player-designed spells**, a **20-node skill tree across five schools**, a placed **Alchemy Desk** and a **Cauldron**. The editor combines supported effects and delivery forms; it does not execute player-written code. Every inscribed item has a unique identity and a saved design. All new sprites were authored in Aseprite: 23 editable layered sources / 61 frames under `assets/sprites/source/alchemy/`, with runtime PNG/JSON sheets under `assets/sprites/alchemy/`.

## First custom spell

1. Press **K** for **Arcane studies**. You begin with **three skill points**. Click **Ember shaping** to learn the Ember effect. Each mastery rank in any school grants one additional skill point; purchases also require the displayed school rank and linked prerequisites.
2. At a Workbench, craft an **Alchemy Desk**, **Cauldron** and **Blank Wand**. Place the two stations on three adjacent floor blocks each. They are passable. Aim at one and press **F** for its own draggable, closable window beside the backpack.
3. At the cauldron, put **2 Coal Ore + 1 Crystal + 1 Wood** in its reagent slots, select **Fire Essence**, then **Brew selected recipe**. The batch warms for three seconds and brews for eight more. Take the two essences from its output.
4. Brew **Arcane Ink** from **2 Alien Fiber + 1 Coal Ore + 1 Crystal + 1 Wood** (11 seconds total; two ink). Depositing ingredients does not start a batch until Brew is pressed.
5. At the desk, deposit **1 Blank Wand + 1 Arcane Ink + 1 Fire Essence**. Choose **Wand**, **Bolt**, **Ember**, **None**, and strength 1. Click the name field, type a name, and press **Enter** to finish editing. The window shows the costs and any missing research.
6. Press **Inscribe unique spell**, then click its output slot to recover it. Drag it onto the hotbar or Ctrl-click it from the backpack. Aim and **left-click** to cast. The unique focus is reusable and spends mana each cast.

Clicking a backpack stack while a station is open deposits it; right-click deposits one. Dragging onto a reagent slot deposits the stack there. Click stored/output slots to withdraw stacks, or right-click for one. Slot tooltips draw above the windows. **F / Esc / X** closes a station. While editing a name, Enter or Esc first finishes text entry.

## Equipment and recipes

| Workbench output | Ingredients |
|---|---|
| Alchemy Desk | Planks 12, Copper Ingot 3, Crystal 2 |
| Cauldron | Iron Ingot 6, Stone 8, Wood 4 |
| Blank Wand | Stick 4, Copper Ingot 1 |
| Blank Staff | Planks 6, Iron Ingot 2 |
| Blank Tome | Alien Fiber 6, Planks 2 |
| Soul Wand | Blank Wand 1, Spirit Essence 2, Arcane Ink 1 |
| Grave Tome | Blank Tome 1, Spirit Essence 3, Bone Fragment 3, Arcane Ink 2 |

Wand, staff and tome determine the crafted item's appearance. They can all carry the supported spell combinations; for Raise Dead they also select a different spectral ally appearance. They do not require extra ammunition. Each inscription consumes one matching blank focus and one ink, plus **one essence per effect per strength level**. Raise Dead also uses **two Bone Fragments**. Two designs with the same name remain separate items with different serial numbers. A character can keep 64 inscribed designs. There is no free reprinting of a saved design; each inscription requires materials.

## Cauldron batches

| Output | Ingredients (including firewood) | Total time |
|---|---|---|
| Fire Essence x2 | Coal Ore 2, Crystal 1, Wood 1 | 11s |
| Frost Essence x2 | Glacial Ice 3, Crystal 1, Wood 1 | 11s |
| Storm Essence x2 | Copper Ingot 1, Crystal 2, Wood 1 | 13s |
| Life Essence x2 | Wildflower 3, Corn 1, Crystal 1, Wood 1 | 11s |
| Spirit Essence x2 | Alien Fiber 2, Crystal 1, Wood 1 | 13s |
| Arcane Ink x2 | Alien Fiber 2, Coal Ore 1, Crystal 1, Wood 1 | 11s |
| Mana Tonic x2 | Life Essence 1, Storm Essence 1, Corn 2, Wood 1 | 15s |

Each cauldron has nine persistent reagent slots, four output stacks, and one timed batch. Ingredients are consumed exactly once on starting. Flooding above 96/255 water, or lava anywhere in its footprint, pauses the batch. Full output prevents completion until space is available. Unfinished jobs and remaining time survive saving and travel. Visited cauldrons advance during active planetary play and inventory/station use; pause, developer controls and orbital/menu views stop them. There is no real-world catch-up.

Breaking a desk or cauldron recovers the station, stored materials and outputs. An unfinished cauldron batch returns its original recipe ingredients once. A removed station cannot keep brewing. Every completed batch grants two XP to its associated school; each inscription grants four XP to its primary school, allowing noncombat progression through resource use.

## Spell construction

| Effect | School | Essence | Behavior |
|---|---|---|---|
| Ember | Destruction | Fire | Direct damage + burning |
| Frost | Destruction | Frost | Direct damage + slowing |
| Storm | Destruction | Storm | Direct damage, usable with any hostile delivery |
| Crystal | Destruction | Storm | Direct damage; bolt pierces two enemies |
| Mending | Restoration | Life | Restores the caster's health |
| Regeneration | Restoration | Life | Restores health each second for a duration |
| Ward | Warding | Storm | Timed protection from creature contact |
| Light | Illumination | Fire | Following cave light |
| Drain | Necromancy | Spirit | Damage plus healing for 35% of actual damage |
| Blight | Necromancy | Spirit | Impact damage plus timed decay |
| Raise Dead | Necromancy | Spirit | Turns a nearby unused corpse into a temporary ally |

**Bolt** and **Self** delivery are available immediately. **Burst** and **Chain** require their skill-tree nodes. Bolt, Burst and Chain need at least one hostile effect; support-only designs use Self. Self with a hostile effect releases a short pulse around the caster. Support components apply once to the caster on a successful cast; hostile components travel to or strike enemies. For example, a Drain/Ward bolt raises the caster's barrier immediately, then steals life if it hits.

**Dual weaving** allows two different learned effects in one spell. Strength has three levels and requires matching primary-school rank. Strength increases direct damage, healing, wards, summon damage and light duration. Duration increases supported timed effects. Area affects burst radius and chain count/range. Inapplicable tuning is shown as n/a and ignored. More strength, duration, area and elaborate forms raise mana cost; the editor previews the resulting cost and recovery. Materials scale with strength. Mana costs remain bounded to 190, while full mastery across all five schools permits 200 maximum mana.

Bolts, bursts, chain segments and summoned attacks respect solid terrain and closed doors. Burst placement must be visible and within 16 blocks; its enemies also need a clear path from the burst center. Chain targets are selected by proximity with a clear path for each bounce. Fire extinguishes in water. Frost, burn and blight refresh their own timed effect rather than stacking unlimited copies. Books and crafted focuses cannot mine blocks or harvest plants.

All existing mana regeneration, tonic recovery, original spell equipment and their crafting recipes remain available. Wards still do not stop lava; Lumen does not grow crops or create torch warmth. Support and hostile components use their respective school mastery bonuses. Crafted healing, wards and healing mana costs can receive the additional tree perks below.

## The skill tree

Each node costs one point. School mastery still has ranks 1-5 at **0, 30, 90, 180, 300 cumulative XP**. The character starts with three points and can earn 20 more from five schools' rank increases. Hover a node for its full effect and prerequisites. Green is learned, blue is currently learnable, and dark nodes need more rank, points or prerequisites.

| School | Nodes and requirements |
|---|---|
| Destruction | Ember shaping (rank 1); Frost shaping (rank 1); Storm shaping (rank 2, Ember); Crystal shaping (rank 3, Frost) |
| Restoration | Life binding (rank 1); Regeneration (rank 2, Life binding); Vitality (rank 3, Regeneration: +15% crafted healing); Renewal (rank 4, Vitality: crafted healing costs 20% less mana) |
| Warding | Ward shaping (rank 1); Aegis (rank 2, Ward: +15% crafted ward strength); Ward weaving (rank 3, Aegis: +20% crafted ward duration); Bulwark (rank 4, Ward weaving: +25% crafted ward strength) |
| Illumination | Light shaping (rank 1); Dual weaving (rank 2, Light); Expanding sigils (rank 2, Light: Burst); Linked sigils (rank 3, Expanding sigils: Chain) |
| Necromancy | Soul study (rank 1: Drain and bone drops); Blight (rank 2, Soul study); Grave calling (rank 2, Soul study: Raise Dead); Spectral legion (rank 4, Grave calling: three simultaneous allies) |

K also has a **Spell guide** tab for original equipment and **My creations** for the character's saved custom focuses. Original pre-alchemy equipment continues to work without new research gates; newly introduced Soul Wand and Grave Tome require the matching necromancy research.

## Necromancy

Learn **Soul study** to use Drain and cause defeated creatures to leave one Bone Fragment each. The existing ordinary loot is still awarded; repeated callbacks do not duplicate bones. **Soul Wand** is a ready-made life-drain focus, or Drain can be combined with another effect in the desk.

After learning **Grave calling**, equip a Grave Tome or a custom Raise Dead focus. Fallen creatures appear as bone remains when Soul study is known. Aim near those remains and cast. The corpse must be within 12 blocks of the player and have a clear line of sight and a usable summon space. A corpse can be raised once; the spent flag is saved. Failed raises do not spend mana. A blank focus or essence does not replace the need for a corpse when casting.

Raised allies are temporary spectral creatures, visually separate from enemies. They follow the player, find nearby visible enemies, attack with recovery between hits, and avoid attacking through terrain. They do not attack the player or robot. Their damage grants Necromancy XP. Base research permits one ally; Spectral legion raises that limit to three. Wand, staff and tome inscriptions produce wraith, bone-hound and bone-servitor appearances. Duration is capped at 60 seconds. Raising an unused corpse grants eight Necromancy XP.

Active summons save their remaining life, position and attack recovery. They resume once when loading on that planet. Leaving the planet or respawning dismisses them. A used corpse does not become reusable after travel or saving. New Game clears learned nodes, created designs, timed regeneration and summons, and restores the three initial skill points.

## Validation and art

`tests/spellcraft_check.gd` covers actual skill clicks, rank/prerequisite/point checks, F interaction, independent station slots, name-field input, all seven brews, timing/flooding, atomic inscription, same-name unique items, dual effects, mana costs, custom equipment and cooldown saves, station recovery, life drain, bone loot, corpse reuse, summon limits/attacks/walls/expiry/save resume, bursts, blight and combined regeneration/ward effects.

`tests/spellcraft_preview.gd` renders the [native art](tests/spellcraft_art_review.png), [desk](tests/alchemy_spell_builder.png), [cauldron](tests/cauldron_brewing.png), [skill tree](tests/magic_skill_tree.png), [creation library](tests/custom_spell_library.png) and [raised ally / custom casting](tests/spellcraft_necromancy_gameplay.png). The main Aseprite export and verification workflows include the new assets.

For testing: **F3 > Magic > Grant Magic Test Kit** includes the stations, blanks, reagents and necromancy focuses. The separate **Unlock magic research (testing)** button grants school mastery and tree research for experiments. Normal kit grants do not purchase research, and new games do not receive test equipment.
