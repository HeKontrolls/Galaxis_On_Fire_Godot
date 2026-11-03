# Shovel sprites

Seven 32 x 40 sprites authored inside Aseprite with three editable layers and one named tag per material. Each retains the tool grip at (16,32). Wood has a carved spade; Stone, Copper, Iron, Gold, Diamond and Netherite use distinct material faces and edge highlights.

Editable source: `assets/sprites/source/frontier/shovels.aseprite`.

`tools/design_shovels_aseprite.lua` constructs the original document in Aseprite. After manual edits, run `tools/export_shovels_aseprite.lua`; rebuilding the design would replace the source edits. `tools/verify_shovels_aseprite.lua` compares every exported visible pixel against its native source and checks the grip. The normal project export and verification scripts include shovels.
