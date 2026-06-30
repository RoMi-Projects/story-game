# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Stardew Valley–style 2D pixel game in **Godot 4.7** (GDScript), targeting Steam
then mobile. **All art is generated procedurally** by Python/Pillow scripts — never
hand-edit files under `assets/`; change the generator and regenerate.

## Commands

```sh
# Regenerate all art (after editing tools/*.py)
python3 -m pip install Pillow        # one time
python3 tools/generate_assets.py     # rewrites assets/*.png (incl. the bitmap font)

# Import assets headlessly (run once after generating, before tests)
godot --headless --import

# Run the full regression suite (exits non-zero on any failure)
godot --headless --script res://tests/run_tests.gd

# Smoke-boot the game headlessly
godot --headless --quit-after 120

# Open the editor / run the game
godot --path .                       # then press F5
```

There is no single-test runner: `tests/run_tests.gd` is one `SceneTree` script
that calls every `_test_*` method from `_initialize()`. To run a subset, comment
out calls in `_initialize()` or add a temporary script. CI
(`.github/workflows/tests.yml`) runs the suite + smoke-boot on every PR and on
`main`.

## Architecture

**Pixel-perfect rendering.** Viewport is 320×180 upscaled to 1280×720 with
`stretch/mode=canvas_items` and Nearest texture filtering. Keep art at native
pixel sizes and integer scales or it blurs.

**Bitmap UI font.** `tools/pixel_font.py` draws `assets/font.png` + a BMFont
`assets/font.fnt`, imported as a fixed-size FontFile so text stays crisp. The
theme `assets/ui_theme.tres` sets it as `default_font` with `default_font_size=7`
(must match the `.fnt` size to render 1:1). Setting `gui/theme/custom` **replaces**
Godot's default theme entirely, so `ui_theme.tres` must define Panel/Button
styleboxes itself — otherwise popups lose their background.

**Autoload singletons** (in `project.godot` `[autoload]`, persist across scenes):
- `InteractionManager` — each frame, routes the `interact`/`pickup` buttons to the
  single *nearest* registered interactable. Objects register/unregister themselves
  on the player entering/leaving their `Area2D`. An interactable must expose
  `on_primary()` + `global_position`; `on_secondary()` is optional (furniture
  pickup).
- `QuestManager` — the "Take Out the Trash" quest state machine
  (`NOT_STARTED→ACCEPTED→COLLECTING→DELIVERED→COMPLETED`). Tracks the 8 collected
  trash piece IDs; transitions are guarded (`_advance(next, required)` no-ops if
  not in the required state). Emits `changed`; objects/markers/HUD subscribe.
- `Inventory` — picked-up items, with a quest-item flag (⭐).
- `GameState` — carries the player spawn position across a door/scene change.

**Class hierarchy (reuse-driven):**
- `Character` (`scripts/character.gd`, `extends CharacterBody2D`) — shared
  walking, facing, and 4-row×4-frame walk-cycle animation. `walk_speed` is
  `@export`ed and set per scene. **`Player`, `Desi`, and the garden `Mouse` all
  extend this**; a new walking character should too and just decide *where* to
  walk. (`Mouse` runs with `collision_layer`/`mask = 0` and clamps itself to the
  garden bounds, so it never fights the physics engine while chasing.)
- `QuestObject` (`scripts/quest_object.gd`, `extends StaticBody2D`) — solid
  inspect/use objects (trash can, container). Owns sprite + interaction
  registration + inspect popup + a quest marker shown when `_wants_marker()` is
  true. Subclasses define `on_primary()`, `item_name()`, `description()`,
  `_wants_marker()`. `TrashPiece` extends it too but has no collision so the
  player walks over it.

**Combat.** The `Mouse` chases the player and, on contact, stores the player's
position in `GameState` and swaps to `scenes/Combat.tscn` (a real scene swap, not
an overlay). Combat is **one player action** (throw bag / scream / run), then —
if unresolved — **one mouse turn**, then it ends; there is no multi-round loop.
The odds live in `scripts/combat_rules.gd` as pure static functions taking a
`RandomNumberGenerator`, so they're unit-tested without the scene. Outcomes route
back via `change_scene_to_file`: any non-loss returns to the garden with the
mouse suppressed (`GameState.suppress_mouse()`); a loss goes to the house and
sets `flag_mouse_loss()`. `Desi._ready` (house only) calls `activate_mouse()` so
the mouse respawns on the next garden visit, and consumes `take_mouse_loss()` to
walk over and react. A missed throw calls `QuestManager.drop_bag()` (resets the
collection to 0; pieces reappear on the next scene load).

**Cross-scene state.** Trash pieces live in both `House.tscn` and `Garden.tscn`,
each with an `@export piece_id`. On `_ready` a piece frees itself if its ID is
already collected in `QuestManager`, so collected trash stays gone across the
door transition. A test asserts the world holds exactly `TRASH_TOTAL` (8) pieces.

**Scene/script pairing.** Most `scenes/X.tscn` has a sibling `scripts/x.gd`. The
main scene is `scenes/House.tscn`; `Garden.tscn` is reached via `Door` nodes that
set `GameState` spawn then `change_scene_to_file`.

## Conventions specific to this repo

- `tools/*.py` use **4-space indentation** (not tabs); `.gd`/`.tscn` files use tabs.
- `.tscn` files are hand-authored text — when adding nodes, keep `load_steps` and
  `ext_resource` IDs consistent.
- In `--script` SceneTree mode, autoload globals are **not** bound. Tests load the
  autoload scripts directly with `load("res://scripts/x.gd").new()` instead of
  referencing the `QuestManager`/`Inventory` globals.
- Adding/removing trash pieces means updating the count in both scenes and
  `QuestManager.TRASH_TOTAL` (the world-count test enforces they agree).
