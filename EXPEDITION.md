# First expedition: repair the escape pod

Your escape pod has crashed while the main ship remains in orbit. Robot companion **R0-VR** helps restore the pod's ascent drive. New games start with empty inventory and hotbars. Choose a star, then its **Temperate forest** planet. This guarantees access to wood, soil and the basic ores before the damaged drive locks travel. R0-VR starts and advances the quest with **E**, **F**, or the dialogue button. **J** folds the objective tracker. Progress is remembered even when tasks are done early or gathered materials are later used.

1. Gather **20 Wood and 12 Stone**. Hands gather wood; craft a workbench and Wood Pickaxe before mining stone. R0-VR supplies four torches.
2. Place a **Workbench and Furnace**, and make a **Stone Pickaxe and Wood Sword**. R0-VR supplies a hoe, watering can and six seeds.
3. Build a **lit shelter** and **harvest mature corn**. Shelter requires twelve surviving player-placed building blocks nearby, a player-built roof above the character, and a nearby torch. Till dirt, plant seeds, water the soil and harvest when mature.
4. Make a **Copper Pickaxe and Copper Sword**. Furnace processing retains its existing heating and smelting times.
5. Make an **Iron Pickaxe**, follow the tracker's underground signal, defeat the **90 HP sentinel**, and press **F** beside the drive core. The core is secured in quest state rather than loose inventory, so it cannot be trashed or lost on death.
6. Craft **two Hull Plates and one Drive Coil** at the workbench. Each plate costs four Iron Ingots and eight Planks. The coil costs four Copper Ingots, four Iron Ingots and two Crystal. Return to the escape pod and press **F**; installation consumes the parts once and unlocks travel.
7. Launch with **G** or **F beside the repaired pod**, return to the main ship in orbit, then land on another planet to complete the first voyage.

The crashed pod and salvage chamber are created once on the untouched first planet. Saving preserves the quest stage, task history, secured core, guardian health/death, repair status and site coordinates. Loading never recreates the chamber or resurrects its sentinel. Existing saves without expedition data retain their original terrain and unrestricted travel; start a new game to play the chain.

The 192x112 escape pod, separate orbital ship, twelve-frame robot companion and all salvage sprites were authored in Aseprite, with editable sources under `assets/sprites/source/expedition`. See the [gameplay review](tests/expedition_preview.png).

Validation: `tests/expedition_check.gd` exercises stage requirements and rewards, station crafting, shelter/harvest recognition, actual combat, repair costs, partial/completed save restoration, travel restrictions and arrival on a second planet. Run with the normal renderer and `-- --preview` to refresh the single review sheet. `tools/verify_expedition_aseprite.lua` verifies all exported pixels against their native sources.

The main ship appears in the system viewer around the visited planet and as a distant ship crossing the surface sky. The damaged pod rests tilted on a flat, scraped dirt floor with displaced dirt and stone along both sides. Torn plating, exposed machinery and broken landing parts are painted in Aseprite. New expeditions spawn beside the crash, with R0-VR nearby. See the [crash-site preview](tests/crash_site_preview.png).

Existing expedition saves retain quest progress and repair status. A one-time crash-site migration searches for untouched natural ground clear of buildings, crops and occupants; it leaves terrain alone if no safe site is available. The site is never rebuilt after the player mines or changes it. Saves without expedition data retain their original terrain. `tests/crash_site_check.gd` checks flat support, side mounds, protected construction and repeat-load preservation across three seeds. The robot also replaces the old NPC visually in legacy worlds.

## Developer travel

Press **F3** in the galaxy or solar system view to open developer controls on the **Travel** tab and enable free travel. Choose any of the eight planet types to land on that type in the currently selected star system. The type lookup respects the different ordering of planets around each star. Close the panel with F3, Escape, or X to browse and land through the normal map controls while free travel stays enabled.

On a surface, **G** returns to orbit without requiring pod repairs. F3 also has a Travel tab for switching types directly or returning to orbit. **Free Travel: OFF** restores expedition rules; if an unfinished expedition would lock the current test planet, it returns you to orbit first. New games start with those rules enabled. Free-travel state is saved with the game so a test save on a locked planet can still be loaded and left; older saves default to normal rules.

Developer travel preserves the current expedition stage, home planet, and objective records. Testing does not initialize a campaign on a desert/ice/lava planet or award quest progress. The world and inventory can still be changed normally during testing. `tests/dev_travel_check.gd` exercises actual F3 and mouse input, all eight types in a different star system, orbit controls, paused objective credit, saves, legacy defaults, and New Game reset. [Galaxy controls](tests/dev_travel_galaxy.png) ? [Solar system controls](tests/dev_travel_system.png).
