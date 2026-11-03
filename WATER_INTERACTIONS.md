# Water movement, ripples and interface fixes

Swimming upward continues while any part of the player touches water. The stronger upward stroke provides enough clearance to leave the surface, and holding jump/swim while moving into a bank enables a swept one-block step. The upward sweep rejects obstructed paths: low ceilings still block the exit. Shallow puddles retain normal walking speed and ground-jump strength.

`scripts/water_ripples.gd` tracks visible players, the robot NPC, hostile mobs and small fauna. Entry/exit creates a splash; moving at the surface creates spaced ripple rings. Mobs stopped just above the water by collision also trigger contact. Effects follow the actual partial-water surface, expire after 0.8 seconds and are capped at 64. Teleports and initial loading do not create splashes, and these visual effects never add or remove fluid. Planet resets clear all transient effects.

The editable source is `assets/sprites/source/underground/water_interactions.aseprite`, authored with native Aseprite scripting. It has two layers, sixteen frames and ripple/splash animation tags. The runtime sheet and frame/pivot JSON live in `assets/sprites/underground/`. Design, export and verification scripts are `tools/design_water_interactions_aseprite.lua`, `export_water_interactions_aseprite.lua` and `verify_water_interactions_aseprite.lua`; main artwork export/verification includes them. Native/export verification checks all 24,576 pixels and binary alpha.

`scripts/ui_text.gd` measures both width and height, shrinks labels when necessary and ellipsizes exceptionally long labels. Main menus, disabled menu buttons, character creator controls, dev buttons, crafting actions and station recipe buttons use this layout. Free Flight has a wider button and matching click area.

Small animals use a committed direction after encountering an obstacle, a short pause when trapped, and a dead zone when the player is directly over them. Rabbits no longer alternate fleeing and obstacle turns every frame; blocked rabbits stop their hop animation.

## Checks and previews

- `tests/water_actor_ui_check.gd`: exits on both shores at 30/60/120 FPS, collision/low-ceiling safety, puddle movement/jumps, player/NPC/mob/critter splashes and wakes, collision contact, unchanged liquid volume, rabbit ledge/perch stability, font metrics, recipe labels and enlarged Free Flight hit testing.
- `tests/water_lighting_input_check.gd`: existing liquid, lighting and held-input behavior.
- `tests/ground_life_check.gd`: ecology generation, actual player movement, plant reactions, fauna, harvesting and saving.
- `tests/water_actor_ui_preview.gd`: normal-renderer [water interaction preview](tests/water_ripples_gameplay.png) and [dev button layout](tests/dev_button_fit.png). Actors are positioned at the surface together to inspect their effects.

Run checks with Godot `--headless --path . --script tests/<name>.gd`. Run the preview with the normal renderer.
