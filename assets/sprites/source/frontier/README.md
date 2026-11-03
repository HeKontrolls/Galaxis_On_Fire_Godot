# Frontier character and crafting set

These are the editable Aseprite documents used by the Godot game. All art was drawn, layered, tagged and exported through Aseprite's native scripting API.

| Document | Canvas | Frames | Contents |
| --- | --- | ---: | --- |
| `captain.aseprite` | 32 x 40 | 38 | Rounded face, chestnut hair, teal shirt, blue trousers and brown shoes; four idle, six walk and nine jump poses in each direction |
| `elder.aseprite` | 32 x 40 | 24 | Silver hair/beard, leather coat, satchel and walking staff; four idle and eight walk poses in each direction |
| `tools.aseprite` | 32 x 40 | 13 | Wood/stone/copper/iron pickaxes, wood/copper/iron swords and axes, hoe, hammer, watering can |
| `captain_parts.aseprite` | 8 x 12 | 3 | Short sleeve, bare forearm and hand for articulated tool and eating poses |
| `stations.aseprite` | 32 x 32 | 8 | Four workbench lamp frames and four furnace flame frames |

Open the relevant document in `C:\Program Files\Aseprite\Aseprite.exe`, edit its layers and frames, and save it. Run this from the Godot project root to export the saved artwork:

```powershell
& .\tools\export_aseprite_art.ps1
```

The helper exports transparent PNG frames, reference sheets and JSON animation durations to `assets/sprites/redesigned/`. It exports the saved documents without repainting their contents. Godot reads actor and station tag timing from the exported metadata.

Keep the established animation tag names. Each tool and arm-part tag contains one frame. Tool grips are at pixel (16,32), and the watering-can rose is at (29,18). Arm segments connect (4,1) to (4,11). Actor floor contact is the bottom edge at y=40; the game renders these sprites at native pixel size. Stations retain a two-tile-wide, one-tile-high gameplay footprint, with their decorative upper half extending above it.

The initial art construction is in `tools/design_sprites_aseprite.lua`. The subsequent player revision is in `tools/redesign_player_aseprite.lua`; it replaces only the captain and arm documents, then exports them. Reconstructing the original set requires running that player revision afterward. For ordinary edits, use the export helper above so hand edits remain intact.

The character is an original design informed by Terraria's readable, compact proportions. The runtime's cursor aim, shoulder sweep, elbow bend and head occlusion live in `scripts/player_pose.gd` and `scripts/game.gd`. The tModLoader [composite arm API](https://docs.tmodloader.net/docs/stable/class_player.html) and [example swing](https://github.com/tModLoader/tModLoader/blob/stable/ExampleMod/Content/Projectiles/ExampleSwingingEnergySwordProjectile.cs) informed the arm/hand separation and aim-relative sweep. No Terraria art is distributed.

Source-to-export verification is in `tools/verify_aseprite_art.lua`; `tests/aseprite_sources_check.log` records all 86 PNG frames matching their Aseprite document pixels. Godot pose, scale, animation, grip and pouring checks are in `tests/aseprite_art_check.gd`. `tests/player_mouse_pose_check.gd` checks input, cursor guards, bone lengths, recovery, mirroring, overhead combat and current runtime pixels; `tests/player_mouse_pose_preview.png` shows the revised character and eight poses.
