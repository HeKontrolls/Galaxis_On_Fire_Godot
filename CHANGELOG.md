# Changelog

Committed numbered builds have matching annotated Git tags. A prepared build receives its tag when committed through Git Commit App. Older unnumbered commits remain in Git history.

## [v0.2.0-alpha+build.3] - 2026-11-04 - Arms, Armor and Night Encounters

### Added

- Equipment tab with helmet, chest, boots, shield, and two accessory slots. Equipping transfers one physical item; swaps and removal return it to the backpack.
- Fiber, Copper, and Iron armor sets with 4/8/12 total defense and 0%/5%/10% movement penalties, plus Scout Charm and Bone Ward accessories.
- Wood, Copper, and Iron shields with directional right-click blocking, guard consumption, guard breaks, recovery, and a HUD meter. Melee/empty-hand blocking preserves tool, bow, and building controls.
- Animated Aseprite armor for both character models, shield/accessory icons, separate worn sleeves, and remote-player equipment rendering.
- Equipment and guard persistence through saves, multiplayer reconnects, and planet travel. Existing saves start with empty equipment slots.

- Six craftable melee weapons: Wood, Copper, and Iron Spears, Iron Dagger, Iron Warhammer, and Crystal Blade.
- Mouse-directed thrusts, individual weapon recovery/damage/reach, heavy knockback, and limited multi-target sweeping attacks.
- Layered Aseprite weapon sources, transparent runtime artwork, and matching inventory/held/remote-player presentation.
- Additional surface monsters, slimes, and flyers at night, selected for each planet climate. Spawning builds at dusk, respects every co-op player's view, and is capped locally and globally.
- Offscreen dawn cleanup and bounded reusable night encounter slots; night state persists in saves. Background walls and liquids prevent spawns inside their footprint.

### Improved

- Melee attacks prioritize nearby targets and sweep knockback against terrain.
- Complete player wiki drafts with an Armor and Equipment guide, current combat and wildlife guides, navigation, and a synchronized copy-and-paste pack.
- Project completion instructions require version/build metadata, patch notes, and wiki updates before handing work back for a commit.

### Validation

- Equipment checks: 170 passed; two-process multiplayer checks: 26 host and 37 client passed, including equipping through input RPC, shield hold/release, reconnects, and travel.
- Aseprite validation: 23 equipment source files and 890,336 matching source/export pixels, with rendered armor/model and backpack reviews.

- 222 weapon/night checks passed: crafting, damage, reach, cleave, blocked attacks, knockback, spawn climate/visibility/limits, client authority guards, saves, and snapshot encoding.
- Existing ranged-weapon and tool-progression regression checks passed.
- Rendered all six weapon poses in both directions and a generated planet with nighttime encounters. Aseprite verification confirmed 9,984 exported pixels match the six layered sources.

- Arms, Armor and Night Encounters

## [v0.1.0-alpha+build.2] - 2026-11-04 - Multiplayer Expeditions and Ally Spacing

- Multiplayer Expeditions and Ally Spacing

### Added

- Shared-world co-op for up to eight captains, including the host.
- Multiplayer setup with Host Game and Join Game tabs, reached through one main-menu button.
- Hosting from a new expedition, the current single-player save, or a selected Godot save file.
- LAN server browser showing server names, addresses, player counts, build versions, and world readiness.
- Direct IP/hostname joining, saved server addresses, connection cancellation, and disconnect messages.
- Separate guest characters, inventories, hotbars, tool durability, health, and magic progress.
- Host-authoritative mining, building, combat, pickups, and shared station inventories/crafting.
- Guest progress stored in the host's save and restored when the same player reconnects.
- Group travel following the host to the next planet, with guest inventories retained.
- Windows Firewall permission dialog with Allow and Decline options. Allow requests Windows administrator approval for executable-specific UDP rules; Public network access is optional and off by default.

### Improved

- HP and MP now share one status panel, with equipped-tool details and the magic shortcut underneath.
- Backpack/crafting shortcuts and their hover labels repositioned to fit the combined status panel.
- Host menus keep the shared world running while guests continue playing.
- New co-op expeditions use a separate save file, and ending hosting restores the previous local save destination.
- Compressed, chunked world synchronization with acknowledgements and changed-block terrain updates.
- Remote players use the existing Aseprite character/tool artwork, with synchronized projectiles and summoned allies.

### Fixed

- Raised allies no longer share the same spawn, following, or recall position.
- Ally movement checks nearby summons so followers and attackers keep their spacing, including summons owned by other co-op players.
- Overlapping allies in older saves are repositioned when restored, and crowded summon attempts leave the corpse available.
- Nearby Ally labels stagger vertically instead of drawing over one another.
- Losing focus releases guest controls; the host losing focus does not cancel other players' held actions.

### Verification and current scope

- Two local game processes passed 49 network checks covering discovery, joining, movement, inventory authority, mining, placement, pickups, shared workbench crafting, damage, saves, reconnection, travel, and host shutdown.
- Multiplayer menu checks and rendered previews verified the menus, combined HP/MP panel, and firewall consent layout.
- Ally spacing passed checks at 30 and 120 FPS, including combat, recall, legacy saves, co-op occupancy, and crowded terrain; a rendered preview confirmed readable labels.
- Existing station storage/sorting, expedition, wildlife, ranged weapon, and spellcraft checks passed during this work.
- The browser discovers LAN games; internet players can use direct addresses. Hosting over the internet requires router configuration for the selected game UDP port (default 24560).
- Actual cross-PC connections, eight-player load, and administrator-approved firewall rule creation still need testing on the target machines. The checks did not change Windows Firewall settings.

## [v0.1.0-alpha+build.1] - 2026-11-04 - Git Commit

First numbered Godot development build, starting from the existing game.

- Procedural galaxies, solar systems, planetary biomes and deep underground exploration.
- Mining tiers, melee weapons, bows, arrows, housing, farming and food.
- Weather, wind, water, lava, surface life and underground creatures.
- Fueled power generation, wiring, switches, lights and logic circuits.
- Magic, mana, elemental weapons, healing, wards and mastery.
- Alchemy desks, cauldrons, custom spellcrafting, skill trees and necromancy.
- Editable Aseprite artwork and gameplay verification scripts.
- Git Commit

