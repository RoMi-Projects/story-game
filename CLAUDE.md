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
- `BuildMode` — a dev tool: the `toggle_build_mode` key (B) shows/hides a
  screen-space `CanvasLayer` overlay drawing the 16px tile grid (`TILE`) with
  column/row indices, to make hand-placing nodes in the `.tscn` files easy. It
  aligns 1:1 only because the camera shows the whole 320×180 world unscrolled.

**Class hierarchy (reuse-driven):**
- `Character` (`scripts/core/character.gd`, `extends CharacterBody2D`) — shared
  walking, facing, 4-row×4-frame walk-cycle animation, **and `wander(delta)`**
  (roam-box strolling, tuned by the `@export`ed `roam_min`/`roam_max`/`pause_*`
  set per scene). **`Player`, the garden `Mouse`, and (via `InteractiveCharacter`)
  `Desi` and `Cat` all extend this**; a new walking character should too and just
  decide *where* to walk. (`Mouse` and `Cat` run with `collision_layer`/`mask = 0`
  and clamp/keep to the garden roam box, so they never fight the physics engine.)
- `InteractiveCharacter` (`scripts/core/interactive_character.gd`, `extends
  Character`) — a walking character the player can talk to: it registers with
  `InteractionManager` while the player is inside its `InteractionArea` and offers
  a `_say()` dialogue helper. **`Desi` (npc) and `Cat` (Baby) extend it**;
  subclasses override `on_primary()` + `_speaker()` (and optional
  `_on_player_entered/exited()` hooks).
- `QuestObject` (`scripts/quest/quest_object.gd`, `extends StaticBody2D`) — solid
  inspect/use objects (trash can, container). Owns sprite + interaction
  registration + inspect popup + a quest marker shown when `_wants_marker()` is
  true. Subclasses define `on_primary()`, `item_name()`, `description()`,
  `_wants_marker()`. `TrashPiece` extends it too but has no collision so the
  player walks over it.

**Combat.** Both encounters share `CombatScene` (`scripts/combat/combat_scene.gd`,
`extends Control`), which owns the dice seed, the `_announce()` message beat, the
menu lock, `_lose_bag()`, and the routes home (`_return_to_garden()` /
`_retreat_to_house(enemy)`). Each fight is **one player action**, then — if
unresolved — **one enemy turn**, then it ends; there is no multi-round loop. The
odds live in `scripts/combat/combat_rules.gd` as pure static functions taking a
`RandomNumberGenerator`, so they're unit-tested without a scene.
- **Mouse** (`combat.gd` / `combat.tscn`): the `Mouse` *chases* and, on contact,
  swaps scenes. Actions: throw bag / scream / run. A non-loss returns to the
  garden with the mouse suppressed (`GameState.suppress_mouse()`); a loss goes to
  the house. A missed throw calls `QuestManager.drop_bag()` (count → 0).
- **Cat / Baby** (`cat.gd` + `cat_combat.gd` / `cat_combat.tscn`): the `Cat` is an
  `InteractiveCharacter`; her fight starts **on interaction, only while
  `QuestManager.is_carrying()`** (otherwise she just meows with an angry
  portrait). Actions: pet (20% win → happy sprite swap) / call / go away. On the
  cat turn she may **break the bag** (50%): `_lose_bag()` + retreat to the house.
  Baby is *not* suppressed — she stays in the garden.

Losses set `GameState.flag_loss(enemy)` ("mouse"/"cat"); `Desi._ready` (house
only) calls `activate_mouse()` and consumes `take_loss()` to walk over and react
to the right culprit.

**Cross-scene state.** Trash pieces live in both `scenes/world/house.tscn` and
`scenes/world/garden.tscn`, each with an `@export piece_id`. On `_ready` a piece
frees itself if its ID is already collected in `QuestManager`, so collected trash
stays gone across the door transition. A test asserts the world holds exactly
`TRASH_TOTAL` (8) pieces.

**Project layout.** Code and scenes are grouped by **domain**, with matching
subfolders under `scripts/` and `scenes/`: `autoload/` and `core/` (scripts only),
`actors/`, `world/`, `quest/`, `combat/`, `ui/`. File names are **snake_case**
throughout (scenes too: `house.tscn`, not `House.tscn`). `assets/` stays flat
(generated). The main scene is `scenes/world/house.tscn`; `garden.tscn` is reached
via `Door` nodes that set `GameState` spawn then `change_scene_to_file`. Most
`scenes/<domain>/x.tscn` has a sibling `scripts/<domain>/x.gd`. References between
files are explicit `res://` paths, so when moving a file, rewrite every reference
to it (in `.tscn`/`.tres`, `project.godot`, and `tests/`) and reimport.

## Conventions specific to this repo

- `tools/*.py` use **4-space indentation** (not tabs); `.gd`/`.tscn` files use tabs.
- `.tscn` files are hand-authored text — when adding nodes, keep `load_steps` and
  `ext_resource` IDs consistent.
- In `--script` SceneTree mode, autoload globals are **not** bound. Tests load the
  autoload scripts directly with `load("res://scripts/<domain>/x.gd").new()` (e.g.
  `scripts/autoload/quest_manager.gd`) instead of referencing the
  `QuestManager`/`Inventory` globals.
- Adding/removing trash pieces means updating the count in both scenes and
  `QuestManager.TRASH_TOTAL` (the world-count test enforces they agree).
