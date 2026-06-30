# Story Game

A Stardew Valley–style game. The player walks around a decorated house and an
adjoining garden (keyboard or on-screen buttons), talks to an NPC (Desi),
inspects or picks up furniture into an inventory, and completes the first
quest — "Take Out the Trash". Built in **Godot 4**, with all pixel art
generated from scratch.

## Project layout

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot project settings (rendering, input map, autoloads, main scene) |
| `scenes/House.tscn` | The house: floor, walls, furniture, Desi, the trash can, the garden door |
| `scenes/Garden.tscn` | The garden: grass, fence, path, the trash container, the door home |
| `scenes/Player.tscn` | Character body, sprite, collision shape |
| `scenes/TouchControls.tscn` | On-screen D-pad + action / pickup / inventory / quest buttons |
| `scenes/Desi.tscn` | Desi, the quest-giver, with her head marker |
| `scenes/DialogueBox.tscn` | Bottom message box (portrait, name, text) |
| `scenes/PlaceableItem.tscn` | Generic furniture: inspect or pick up |
| `scenes/ItemPopup.tscn` | Centered popup with an item's picture, name, description |
| `scenes/InventoryPanel.tscn` | Togglable list of collected items |
| `scenes/QuestLog.tscn` | Togglable list of active quests + objectives |
| `scenes/QuestMarker.tscn` | Floating `!` / `✓` icon above quest objects |
| `scenes/Door.tscn` | Walk-in area that loads another scene at a spawn point |
| `scenes/TrashCan.tscn` / `scenes/TrashContainer.tscn` | The quest's collect / deliver objects |
| `scripts/quest_manager.gd` | Autoload: the trash quest state machine |
| `scripts/game_state.gd` | Autoload: carries the spawn point across scene changes |
| `scripts/interaction_manager.gd` | Autoload: routes buttons to the nearest object |
| `scripts/inventory.gd` | Autoload: stores picked-up items |
| `scripts/quest_object.gd` | Shared base for the trash can / container |
| `scripts/*.gd` | One script per scene above (player, npc, door, popups, panels, marker) |
| `assets/*.png` | Generated art (do not edit by hand) |
| `tools/generate_assets.py` | Draws every PNG in `assets/` |
| `tools/pixel_font.py` | Draws the bitmap UI font (`assets/font.png` / `.fnt`) |
| `tests/run_tests.gd` | Headless regression suite |
| `.github/workflows/tests.yml` | CI: runs the suite on every PR and on `main` |

## Regenerate the art

```sh
python3 -m pip install Pillow      # one time
python3 tools/generate_assets.py   # rewrites assets/*.png
```

## Tests

A headless regression suite covers the quest state machine, the inventory's
quest-item handling, the bitmap UI font, the themed popup background, and the
item popup's readable description. Run it locally:

```sh
godot --headless --script res://tests/run_tests.gd
```

It prints a `PASS`/`FAIL` line per check and exits non-zero if any fail.
**GitHub Actions** (`.github/workflows/tests.yml`) runs the same suite — plus a
smoke-boot of the game — on every pull request and on every push to `main`.

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
| Interact / inspect / talk | Space / E / Enter | **A** button |
| Pick up | F | **B** button |
| Inventory | I / Tab | **I** button |
| Quest log | J | **Q** button |

- Stand next to any piece of **furniture** and press Interact to see its name and
  a description. Press Pick up to remove it into your inventory (each item is its
  own placeable unit — groundwork for a future in-game store).
- Walk through the **door** (bottom-left of the house) to reach the garden, and
  the door in the garden to return.

## The "Take Out the Trash" quest

1. A **`!`** floats over **Desi**. Talk to her — she complains the house is
   filthy and the quest is auto-accepted (see it in the Quest log, **J / Q**).
2. The **trash can** now shows a **`!`**. Interact with it to grab the bag —
   Roberto's sprite changes to carry it, and the **Trash Bag** appears in your
   inventory marked with a ⭐ (quest item).
3. Carry it through the door to the **garden**; the **trash container** shows a
   **`!`**. Interact to throw the trash — the sprite returns to normal and the
   Trash Bag leaves your inventory.
4. Return to the house: Desi now shows a **`✓`**. Talk to her for a thank-you
   (and a kiss 💋). From then on she just winks: "Next time don't make me ask
   you!"
