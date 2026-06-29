# Story Game

A Stardew Valley–style game. This first MVP is a single room where a character
walks in four directions (keyboard or on-screen buttons) and bumps into the
walls. Built in **Godot 4**, with all pixel art generated from scratch.

## Project layout

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot project settings (rendering, input map, main scene) |
| `scenes/Main.tscn` | The room: floor, walls + colliders, player, camera, controls |
| `scenes/Player.tscn` | Character body, sprite, collision shape |
| `scenes/TouchControls.tscn` | On-screen D-pad + action button |
| `scenes/Desi.tscn` | Desi, an interactable NPC |
| `scenes/DialogueBox.tscn` | Bottom message box (portrait, name, text) |
| `scripts/player.gd` | Movement, wall collision, walk animation |
| `scripts/touch_controls.gd` | Feeds the on-screen buttons into the input system |
| `scripts/npc.gd` | Proximity detection + open/close dialogue on interact |
| `scripts/dialogue_box.gd` | Show/hide the message box |
| `assets/*.png` | Generated art (do not edit by hand) |
| `tools/generate_assets.py` | Draws every PNG in `assets/` |

## Regenerate the art

```sh
python3 -m pip install Pillow      # one time
python3 tools/generate_assets.py   # rewrites assets/*.png
```

## Run the game

1. Install Godot 4 (see below).
2. Open this folder in the Godot editor, or run from the terminal:
   ```sh
   godot --path .          # opens the editor (imports assets on first run)
   ```
3. Press **F5** (or the Play button) to launch.
4. Move with **arrow keys / WASD** or the **on-screen buttons**. The character
   cannot leave the room.

### Installing Godot 4 on macOS

- Homebrew: `brew install godot`
- Or download the macOS app from <https://godotengine.org/download>

## Controls

| Action | Keys | Touch |
| --- | --- | --- |
| Move | Arrow keys / WASD | On-screen D-pad |
| Interact | Space / E / Enter | On-screen **A** button |

Walk up to **Desi** and press Interact to read her message; press it again to
close the box.
