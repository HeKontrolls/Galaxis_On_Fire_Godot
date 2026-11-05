# Saves and Settings

A save records the expedition and its changed worlds. Settings store preferences such as presentation and sound levels.

## Saving and loading

- Press **F5** to save in single-player, or use the pause menu's save action.
- Use **Load Game** from the main menu to resume the normal save.
- **F9** is the single-player quick-load control where gameplay input permits it.
- **Save & Main Menu** and **Save & Quit** save before leaving through those actions.

The ordinary save is `galaxis_save.json` in Godot's game user-data directory (`user://`). It is separate from the source-code folder and from `version.json`.

## What is preserved?

Saved state includes the character and appearance, inventory and hotbar, tool wear, health, magical progression, expedition objectives, visited planets, terrain edits, and structures. Stations retain stored materials and supported processing state. Weather/time and relevant world-system state are also recorded.

A seed alone cannot restore this progress. Starting a fresh game with the same seed recreates a starting layout, not your previous constructions and equipment.

## Multiplayer saves

New hosted expeditions use `galaxis_multiplayer_save.json`. When the host loads a selected save file, that file becomes the session's save destination. Ending hosting restores the previous local save destination.

Only the host writes the shared world save. Guest character progress is stored there. The guest's `multiplayer_identity.txt` identifies the returning character; the display name alone does not select its saved progress.

## Settings

Settings tabs cover gameplay, video, audio, and control information. Options include day length, underground/night darkness preferences, fullscreen, and master/effects/ambience volumes.

During co-op, the session menu restricts loading another save and changing world settings. End the session before changing those aspects of the expedition.

## Keeping an expedition

Keep a separate copy of an important save before experimenting with developer edits or replacing game/user-data files. A Git source checkpoint is different from a player save; committing the project does not automatically preserve your `user://` expedition.

[Home](Home) · [Wiki Index](Wiki-Index) · [World Generation and Seeds](World-Generation-and-Seeds) · [Multiplayer](Multiplayer)
