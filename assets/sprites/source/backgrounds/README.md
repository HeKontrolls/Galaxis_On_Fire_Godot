# Biome panorama artwork

All sprite pixels are created in Aseprite using its native Sprite, Image, Layer and Tag APIs. The 32 named scene documents correspond to the game's eight climates and four biome regions per climate. Each 640 x 256 source has six editable layers: a landform layer and a detail/vegetation layer for each of three parallax planes. Open a document in Aseprite to revise its palette, composition, plants, cliffs or geological details.

`background_life.aseprite` contains songbird, seabird, firefly and waterfall animation tags, with three frames each. `background_atmosphere.aseprite` contains three aurora frames and three volcanic vapor frames. Their sprites remain decorative and cannot be harvested or collide with the player.

Runtime exports are under `assets/sprites/backgrounds/`. `catalog.json` maps each scene to its climate, biome, wildlife and painted landmark positions. The source panoramas have matching left/right edge pixels for horizontal repetition. Artwork draws at twice its native resolution; the atmospheric sprites use smooth filtering for vapor and aurora gradients.

Landform layers must remain solid below their skyline. Detail layers may contain tree branches and rock arches, but every painted component must connect to the landform, including across the horizontal wrap. The final eight rows form a uniform opaque footing that Godot extends to the bottom of the viewport; this prevents blue sky strips at shorelines and when looking down from hills. Native verification checks all 96 planes for these conditions. `tools/repair_biome_backgrounds_aseprite.lua` repairs the existing layered documents inside Aseprite without regenerating their compositions. The design script uses the same integrity rules for new artwork.

The visual direction follows the landscape variety in the [Terraria biome-background reference](https://terraria.wiki.gg/wiki/Biome_backgrounds): layered forests, cliffs, coastal islands, desert landforms and snowy peaks. These are original Galaxis on Fire sprites; Terraria artwork is not included.

Export saved sources without repainting:

```powershell
& 'C:\Program Files\Aseprite\Aseprite.exe' --batch --script-param root=D:/galaxy_game/Galaxis_On_Fire_Godot --script D:/galaxy_game/Galaxis_On_Fire_Godot/tools/export_biome_backgrounds_aseprite.lua
```

Verify native layers, transparency, panorama seams and every visible exported pixel:

```powershell
& 'C:\Program Files\Aseprite\Aseprite.exe' --batch --script-param root=D:/galaxy_game/Galaxis_On_Fire_Godot --script D:/galaxy_game/Galaxis_On_Fire_Godot/tools/verify_biome_backgrounds_aseprite.lua
```

The normal project art export and verification commands include these sources. `tools/design_biome_backgrounds_aseprite.lua` recreates all 34 documents inside Aseprite and replaces manual edits; use the export command to retain edits.
