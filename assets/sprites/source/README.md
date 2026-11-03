# Editable sprite artwork

Create and edit all new or revised Galaxis sprites with Aseprite, installed at `C:\Program Files\Aseprite\Aseprite.exe`.

Keep layered `.aseprite` originals here, organized to match the exported sprite folders. Preserve animation tags, frame timing, transparency, and the existing sprite's dimensions and grip/pivot alignment. Export game-ready PNGs, frame sequences, or sprite sheets into the matching `assets/sprites/` directory; include JSON animation data when required.

When existing sprite art needs changes, import it into Aseprite and save an editable source before exporting the revision.

The active character, elder, tool and crafting-station set is in [frontier](frontier/README.md). After saving edits in Aseprite, run `tools/export_aseprite_art.ps1` from the Godot project root to refresh the game exports.

New Game character creation uses the layered male/female models and matching articulated arms in [characters](characters/README.md). Hair, eyes, skin, shirts, pants and shoes have native Aseprite palette variants, baked into runtime atlases by the same export command. Existing saves without appearance data retain the frontier captain.
