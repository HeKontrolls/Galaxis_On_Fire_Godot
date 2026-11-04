# Changelog

Each numbered build has a matching annotated Git tag. Older unnumbered commits remain in Git history.

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

