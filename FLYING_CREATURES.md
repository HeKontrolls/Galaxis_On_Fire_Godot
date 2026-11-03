# Flying creatures

Eight climate-specific families add flying enemies alongside the ground monsters:

| Planet | Flyer |
| --- | --- |
| Forest | Mosswing |
| Islands | Reed darter |
| Ocean/continents | Cloud ray |
| Desert | Sand hornet |
| Lava | Ash glider |
| Barren | Shardwing |
| Frozen ocean | Rime moth |
| Tundra | Dusk bat |

Each family has three authored variants and a six-frame wing cycle, all painted in Aseprite. The 144 frames use clustered pixel textures, opaque colors, transparent backgrounds and material-colored edges without black strokes. Editable sources are `assets/sprites/source/monsters/flying_0.aseprite` through `flying_7.aseprite`, with three layers and three animation tags each. Exports include PNG sheets and JSON frame metadata. Use `tools/export_flyers_aseprite.lua` to export manual edits; `tools/design_flyers_aseprite.lua` intentionally repaints the native sources. Both run through Aseprite with the project's `root` script parameter.

Six flyers are seeded per planet. Spawn clearance uses the actual uppermost terrain, liquid or ice surface, so frozen-ocean creatures appear above the ice rather than below it. New populations avoid the landing position. Existing planets receive flyers once on loading; saved appearance, health, defeated state, home position and attack state persist without respawning dead creatures.

Flight combines local patrols, vertical hovering and wider gliding arcs. Nearby visible players trigger a 0.6-second warning, marked by a small amber exclamation mark. The dive aims at the player's position when the warning began; it does not continually track a dodging player. After a hit or a completed dive, the creature has a 2.2-second recovery period and moves toward home. Patrol and recovery contact is harmless. Attacks share the normal player damage cooldown.

Movement is checked in three-pixel substeps to prevent high-speed tunneling through terrain. Flyers stop or slide along obstacles and try moving upward around a local obstruction; this is local obstacle avoidance, not a full cave pathfinder. The body uses the established 24x18 enemy combat box; decorative wing tips extend beyond it. They can be hit with existing weapons and drop Alien Fiber through the normal loot system.

`tests/flying_monsters_check.gd` verifies all eight climates, deterministic generation, safe spawning, one-time migration, real save/load, warning and recovery, fixed dive targets, wall/roof collisions, melee damage and loot. `tools/verify_flyers_aseprite.lua` checks every exported pixel against the native sources, binary alpha, canvas borders and absence of the old black stroke. The main Aseprite exporter and verifier include the flying artwork.

See the [family review](tests/flying_monsters_review.png) and [in-game warning preview](tests/flying_monsters_gameplay.png).
