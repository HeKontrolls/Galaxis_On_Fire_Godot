# Expedition sprites

Nine layered, tagged Aseprite documents supply the crashed/repaired 192x112 escape pod, orbital ship, landing strut, drive core, sentinel, hull plate, drive coil and animated R0-VR robot. `ship_damaged` and `ship_ready` are retained as asset filenames for compatibility; they now depict the escape pod. The main ship uses `orbital_ship`.

All pixels are authored inside Aseprite. `tools/design_expedition_aseprite.lua` recreates the set, including `tools/design_escape_pod_aseprite.lua` for the pod, orbital ship and robot. Do not rerun design scripts to export subsequent manual edits.

The damaged pod has a native pixel-painted breach, exposed wiring, broken plates and collapsed landing parts. Its tilted, partly buried pose is baked into the Aseprite document; the repaired frame remains upright. Pass `--script-param only_pod=true` to `design_escape_pod_aseprite.lua` when intentionally regenerating only the two pod designs. The terrain crater uses existing game blocks, separately from the artwork.

Use `tools/export_expedition_aseprite.lua` to export current native documents and `tools/verify_expedition_aseprite.lua` to compare every exported pixel against its source. Both are included in the main Aseprite workflows. Eight static documents retain two layers and an idle tag; the robot retains two layers and twelve frames with idle/walk tags for east and west. Robot exports and timing metadata go under `assets/sprites/redesigned/robot_guide` for the actor animation system.
