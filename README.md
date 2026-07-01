# Story Game

A Stardew Valley–style game. The player walks around a decorated house and an
adjoining garden with the keyboard, talks to an NPC (Desi),
inspects or picks up furniture into an inventory, and completes the first
quest — "Take Out the Trash". Built in **Godot 4**, with all pixel art
generated from scratch.

## Project layout

Code and scenes are grouped by **domain** inside `scripts/` and `scenes/`, with
matching subfolders. File names are **snake_case** throughout.

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot project settings (rendering, input map, autoloads, main scene) |
| `scripts/autoload/` | Global singletons: `game_state`, `inventory`, `quest_manager`, `interaction_manager`, `build_mode` |
| `scripts/core/` | Reusable bases: `Character` (walking/facing/wander) and `InteractiveCharacter` (talk-to NPCs) |
| `scripts/actors/` & `scenes/actors/` | The player, Desi (npc), the garden mouse, and Baby the cat |
| `scripts/world/` & `scenes/world/` | The house, garden, doors, grid-snapping placeable furniture, the `WorldGrid` occupancy service, and wall fixtures. Walls are a `TileMapLayer` driven by `assets/world_tileset.tres` |
| `scripts/quest/` & `scenes/quest/` | The trash quest objects: can, container, pieces, and the `!`/`✓` marker |
| `scripts/combat/` & `scenes/combat/` | The Pokemon-style mouse & cat encounters (shared `CombatScene` base) + pure `combat_rules.gd` odds |
| `scripts/ui/` & `scenes/ui/` | Dialogue box, item popup, inventory panel, quest log, touch controls, trash counter |
| `scenes/world/house.tscn` | Main scene: floor, walls, furniture, Desi, the trash can, the garden door |
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
4. Move with **arrow keys / WASD**. The character cannot leave the room.

### Installing Godot 4 on macOS

- Homebrew: `brew install godot`
- Or download the macOS app from <https://godotengine.org/download>

## Controls

| Action | Keys |
| --- | --- |
| Move | Arrow keys / WASD |
| Interact / inspect / talk | Space / E / Enter |
| Pick up | F |
| Inventory | I / Tab |
| Quest log | J |
| Build mode (tile grid + command legend) | B |

The game is keyboard-driven; the on-screen touch buttons have been removed for the
desktop build (the `touch_controls` scene is kept for the future mobile target).

- Stand next to any piece of **furniture** and press Interact to see its name and
  a description. Press Pick up to remove it into your inventory (each item is its
  own placeable unit — groundwork for a future in-game store).
- Walk through the **door** (bottom-left of the house) to reach the garden, and
  the door in the garden to return.
- Press **B** for **Build mode** — a developer overlay that draws the world's
  16×16 tile grid with column/row indices (for reading a cell's coordinates when
  hand-placing furniture) plus a **legend of every key command**. Press **B**
  again to hide it.

## The "Take Out the Trash" quest

1. A **`!`** floats over **Desi**. Talk to her — she complains the house is
   filthy and the quest is auto-accepted (see it in the Quest log, **J / Q**).
2. The **trash can** now shows a **`!`**. Interact with it to grab an **empty
   bag** — Roberto's sprite changes to carry it, the bag appears in your
   inventory marked with a ⭐ (quest item), and a **`X / 8` counter** appears at
   the top of the screen.
3. **Hunt down 8 pieces of trash** scattered across the house (5) and the garden
   (3). They are **not** marked — you have to spot them. Walk up to one and press
   Interact to bag it; it vanishes and the counter ticks up. Collected pieces
   stay gone even after walking between the house and the garden.
4. With all **8/8** bagged, the garden **trash container** shows a **`!`**.
   Interact to throw the full bag — the sprite returns to normal and the Trash
   Bag leaves your inventory.
5. Return to the house: Desi now shows a **`✓`**. Talk to her for a thank-you
   (and a kiss 💋). From then on she just winks: "Next time don't make me ask
   you!"

## The garden mouse (combat)

A **mouse** roams the garden. Get too close and it chases you; if it touches you
a **Pokemon-style fight** begins. You get **one action**:

- **Throw Bag** — only shown while you're carrying the trash bag. **30%** to hit:
  on a hit the mouse flees and you keep your bag and your count. On a miss the
  bag is gone — your count resets to **0**, every collected piece returns to the
  world, and you must fetch a fresh bag from the trash can.
- **Scream** — **50%** the mouse flees.
- **Run** — **95%** you escape.

If your action doesn't end the fight, the **mouse takes a turn**: **15%** it
charges and you lose (you wake up back in the house and Desi walks over —
*"You saw the mouse again?"*), otherwise it loses interest and the fight ends.

Once the fight is over the mouse is gone from the garden; it only comes back
after you've returned to the house and come out again.

## Baby the cat (combat)

**Baby** the cat also roams the garden. Walk up and **interact** and she just
meows, crossly — unless you're **carrying the trash bag**, in which case the
interaction turns into a **fight**. You get **one action**:

- **Pet the cat** — **20%** she is charmed: she purrs, you part as friends, and
  you keep your bag.
- **Call him** — bravado; it changes nothing about how the turn ends.
- **Go away** — you always back off and leave.

If you don't win or leave, **Baby takes a turn**: **50%** she shreds your trash
bag — your count resets to **0** and you flee home, where Desi walks over
(*"Baby scared you off again?"*) — otherwise she loses interest and the fight
ends.
