# Native Aseprite expansion artwork

All sprite pixels were authored in Aseprite 1.3.18.6 using its Lua Image, Sprite, Layer and Tag APIs. The six documents here contain editable layers and named animation tags:

- `advanced_pickaxes.aseprite`: Gold, Diamond and Netherite, 32 x 40, shared grip (16,32).
- `advanced_materials.aseprite`: Diamond, Ancient Debris, Netherite Scrap and Ingot.
- `underground_ores.aseprite`: seven natural mineral overlays, four variants each, 16 x 16. Existing inventory element badges are separate.
- `desert_flora.aseprite`: fifteen species, four frames each, 64 x 96 authoring canvas. Native exports trim only transparent headroom and retain the ground pivot; metadata records each resulting height.
- `glacial_ice.aseprite`: four small ice variants.
- `glacial_facets.aseprite`: continuous 64 x 128 crystal faces sampled across terrain blocks to avoid per-block borders.

Run from PowerShell (batch commands can be launched hidden with Start-Process):

```powershell
& 'C:\Program Files\Aseprite\Aseprite.exe' --batch --script-param root=D:/galaxy_game/Galaxis_On_Fire_Godot --script D:/galaxy_game/Galaxis_On_Fire_Godot/tools/export_planet_expansion_aseprite.lua
& 'C:\Program Files\Aseprite\Aseprite.exe' --batch --script-param root=D:/galaxy_game/Galaxis_On_Fire_Godot --script D:/galaxy_game/Galaxis_On_Fire_Godot/tools/verify_planet_expansion_aseprite.lua
```

Normal project art export/verification includes these documents. Verification compares 100 exported frames against their native source pixels and rejects cropped opaque pixels. `tools/design_planet_expansion_aseprite.lua` is the original construction script: rerunning it replaces these six source documents, so use export after manual edits instead.

The revised frozen-ocean spires add two native sources: `glacial_spires.aseprite` (128 x 256, four layers, crystal planes/fractures/frost) and `glacial_edges.aseprite` (16 x 16, three layers, six tagged frames for pointed tips and exposed edges). Runtime exports live in `assets/sprites/glacial_spires/`; they replace the older facet texture in terrain rendering. `tools/export_glacial_spires_aseprite.lua` exports the saved documents without repainting them, and `tools/verify_glacial_spires_aseprite.lua` compares all 34,304 exported pixels and verifies transparent tip corners. Both run through the normal project art commands. `tools/design_glacial_spires_aseprite.lua` recreates only these two native sources inside Aseprite; use export to retain manual edits.
