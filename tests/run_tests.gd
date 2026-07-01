extends SceneTree
## Headless regression suite for the game.
##
## Run locally or in CI with:
##   godot --headless --script res://tests/run_tests.gd
##
## Every check prints a PASS/FAIL line. The process exits non-zero if any check
## fails, so the GitHub pipeline can block a PR that breaks one of these.

var _passed := 0
var _failed := 0


# Stand-ins for interactables: one that can only be inspected, one that can also
# be picked up. Used to test how the pickup button chooses its target.
class _InspectOnly extends Node2D:
	func on_primary() -> void: pass

class _Pickable extends Node2D:
	func on_primary() -> void: pass
	func on_secondary() -> void: pass


func _initialize() -> void:
	_test_quest_advances_through_every_step()
	_test_quest_ignores_out_of_order_steps()
	_test_pieces_are_counted_once_and_remembered()
	_test_world_holds_exactly_enough_pieces()
	_test_desi_has_a_walk_spritesheet()
	_test_character_faces_its_movement_direction()
	_test_throwing_the_bag_resets_the_collection()
	_test_combat_odds_match_the_design()
	_test_cat_combat_odds_match_the_design()
	_test_mouse_respawn_is_remembered_across_areas()
	_test_garden_holds_a_mouse()
	_test_garden_holds_a_cat()
	_test_world_uses_tilemap_walls()
	_test_world_tileset_has_physics()
	_test_world_grid_maps_cells_and_footprints()
	_test_world_grid_tracks_occupancy()
	_test_wall_objects_are_inspectable_fixtures()
	_test_trash_pieces_block_their_tile()
	_test_pickup_targets_the_nearest_pickable()
	_test_mouse_has_a_walk_spritesheet()
	_test_cat_has_a_walk_spritesheet()
	_test_build_mode_starts_hidden_and_toggles()
	_test_build_mode_grid_matches_tile_size()
	_test_build_mode_input_is_mapped()
	_test_build_mode_lists_commands()
	_test_inventory_marks_quest_items()
	_test_inventory_removes_delivered_items()
	_test_ui_font_is_a_crisp_bitmap()
	_test_theme_gives_popups_a_background()
	await _test_item_popup_reads_clearly()
	_report()
	quit(1 if _failed > 0 else 0)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
	print(("PASS " if condition else "FAIL ") + label)


func _report() -> void:
	print("\n%d passed, %d failed" % [_passed, _failed])


# --- quest state machine -------------------------------------------------------

func _test_quest_advances_through_every_step() -> void:
	var quest = load("res://scripts/autoload/quest_manager.gd").new()
	_check("quest starts not started", quest.state == quest.State.NOT_STARTED)
	quest.accept()
	_check("talking to Desi accepts the quest", quest.is_active() and quest.state == quest.State.ACCEPTED)
	quest.take_bag()
	_check("grabbing the empty bag starts the collecting phase", quest.is_carrying())
	for index in quest.TRASH_TOTAL:
		quest.collect_piece("piece_%d" % index)
	_check("bagging every piece fills the counter", quest.all_pieces_collected())
	quest.deliver_trash()
	_check("dumping the full bag reaches the delivered step", quest.state == quest.State.DELIVERED)
	quest.turn_in()
	_check("thanking Desi completes the quest", quest.is_completed() and not quest.is_active())
	quest.free()


func _test_quest_ignores_out_of_order_steps() -> void:
	var quest = load("res://scripts/autoload/quest_manager.gd").new()
	quest.take_bag()
	_check("the bag cannot be grabbed before the quest is accepted", quest.state == quest.State.NOT_STARTED)
	quest.accept()
	quest.collect_piece("too_early")
	_check("trash cannot be collected before the bag is grabbed", quest.pieces_collected() == 0)
	quest.take_bag()
	quest.collect_piece("only_one")
	quest.deliver_trash()
	_check("the bag cannot be delivered before every piece is found", quest.state == quest.State.COLLECTING)
	quest.free()


func _test_world_holds_exactly_enough_pieces() -> void:
	var placed := _count_pieces("res://scenes/world/house.tscn") + _count_pieces("res://scenes/world/garden.tscn")
	var quest = load("res://scripts/autoload/quest_manager.gd").new()
	_check("the world holds exactly TRASH_TOTAL pieces to find", placed == quest.TRASH_TOTAL)
	quest.free()


func _count_pieces(scene_path: String) -> int:
	var count := 0
	for line in FileAccess.get_file_as_string(scene_path).split("\n"):
		if line.begins_with("piece_id = "):
			count += 1
	return count


func _test_character_faces_its_movement_direction() -> void:
	# The shared walking logic the player and Desi both reuse from Character.
	var character := Character.new()
	character.face_towards(Vector2.RIGHT)
	var right_ok: bool = character._facing == "right"
	character.face_towards(Vector2.UP)
	var up_ok: bool = character._facing == "up"
	character.face_towards(Vector2(0.3, -0.9))
	var dominant_axis_ok: bool = character._facing == "up"
	_check("a character faces its dominant movement axis", right_ok and up_ok and dominant_axis_ok)
	character.free()


func _test_desi_has_a_walk_spritesheet() -> void:
	var sheet: Texture2D = load("res://assets/desi_spritesheet.png")
	_check("Desi has a 4-direction walk spritesheet (4 rows x 4 frames)",
		sheet.get_width() == FRAME_WIDTH * 4 and sheet.get_height() == FRAME_HEIGHT * 4)


const FRAME_WIDTH := 16
const FRAME_HEIGHT := 24


func _test_pieces_are_counted_once_and_remembered() -> void:
	var quest = load("res://scripts/autoload/quest_manager.gd").new()
	quest.accept()
	quest.take_bag()
	quest.collect_piece("house_1")
	quest.collect_piece("house_1")
	_check("the same piece is only counted once", quest.pieces_collected() == 1)
	_check("a bagged piece stays remembered across scenes", quest.is_piece_collected("house_1"))
	quest.free()


# --- combat --------------------------------------------------------------------

func _test_throwing_the_bag_resets_the_collection() -> void:
	var quest = load("res://scripts/autoload/quest_manager.gd").new()
	quest.accept()
	quest.take_bag()
	quest.collect_piece("garden_1")
	quest.collect_piece("garden_2")
	quest.drop_bag()
	_check("missing the throw empties the haul",
		quest.pieces_collected() == 0 and not quest.is_piece_collected("garden_1"))
	_check("a dropped bag sends the player back for a new one",
		quest.state == quest.State.ACCEPTED and not quest.is_carrying())
	quest.free()


func _test_combat_odds_match_the_design() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240601
	var trials := 4000
	_check("running escapes about 95% of the time",
		_is_near(_ratio_over_trials(CombatRules.run_escapes, rng, trials), CombatRules.RUN_ESCAPE_CHANCE))
	_check("screaming scares the mouse about half the time",
		_is_near(_ratio_over_trials(CombatRules.scream_scares_mouse, rng, trials), CombatRules.SCREAM_FLEE_CHANCE))
	_check("a thrown bag connects about 30% of the time",
		_is_near(_ratio_over_trials(CombatRules.throw_hits, rng, trials), CombatRules.THROW_HIT_CHANCE))
	_check("the mouse charges about 15% of the time",
		_is_near(_ratio_over_trials(CombatRules.mouse_charges, rng, trials), CombatRules.MOUSE_CHARGE_CHANCE))


func _test_cat_combat_odds_match_the_design() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240601
	var trials := 4000
	_check("petting the cat works about 20% of the time",
		_is_near(_ratio_over_trials(CombatRules.cat_pet_succeeds, rng, trials), CombatRules.PET_SUCCESS_CHANCE))
	_check("calling the cat draws it closer about half the time",
		_is_near(_ratio_over_trials(CombatRules.cat_approaches, rng, trials), CombatRules.CALL_APPROACH_CHANCE))
	_check("the cat breaks the bag about half the time",
		_is_near(_ratio_over_trials(CombatRules.cat_breaks_bag, rng, trials), CombatRules.CAT_BREAKS_BAG_CHANCE))


func _ratio_over_trials(roll: Callable, rng: RandomNumberGenerator, trials: int) -> float:
	var hits := 0
	for _trial in trials:
		if roll.call(rng):
			hits += 1
	return float(hits) / float(trials)


func _is_near(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= 0.04


func _test_mouse_respawn_is_remembered_across_areas() -> void:
	var state = load("res://scripts/autoload/game_state.gd").new()
	_check("the mouse starts out roaming the garden", state.mouse_is_active())
	state.suppress_mouse()
	_check("after a fight the mouse stays gone this visit", not state.mouse_is_active())
	state.activate_mouse()
	_check("returning through the house brings the mouse back", state.mouse_is_active())
	state.flag_loss("mouse")
	_check("a loss names the culprit for Desi once", state.take_loss() == "mouse")
	_check("the loss flag clears after it is read", state.take_loss() == "")
	state.free()


func _test_build_mode_starts_hidden_and_toggles() -> void:
	var build = load("res://scripts/autoload/build_mode.gd").new()
	get_root().add_child(build)
	_check("the build-mode grid is hidden until asked for",
		not build.is_enabled() and not build.grid_is_visible())
	build.toggle()
	_check("toggling build mode shows the grid", build.is_enabled() and build.grid_is_visible())
	build.toggle()
	_check("toggling again hides the grid", not build.is_enabled() and not build.grid_is_visible())
	build.free()


func _test_build_mode_grid_matches_tile_size() -> void:
	var build = load("res://scripts/autoload/build_mode.gd").new()
	_check("the grid uses the world's 16px tile size", build.TILE == 16)
	_check("a 320px-wide world is exactly 20 tiles across", 320 / build.TILE == 20)
	build.free()


func _test_build_mode_input_is_mapped() -> void:
	var settings := FileAccess.get_file_as_string("res://project.godot")
	_check("build mode has a toggle key bound", settings.contains("toggle_build_mode={"))


func _test_build_mode_lists_commands() -> void:
	var build = load("res://scripts/autoload/build_mode.gd").new()
	_check("build mode advertises the key commands as a legend", build.COMMANDS.size() >= 4)
	build.free()


func _test_garden_holds_a_mouse() -> void:
	var garden := FileAccess.get_file_as_string("res://scenes/world/garden.tscn")
	_check("the garden contains a mouse to fight", garden.contains("scenes/actors/mouse.tscn"))


func _test_garden_holds_a_cat() -> void:
	var garden := FileAccess.get_file_as_string("res://scenes/world/garden.tscn")
	_check("the garden contains Baby the cat", garden.contains("scenes/actors/cat.tscn"))


# --- grid world ----------------------------------------------------------------

func _test_world_uses_tilemap_walls() -> void:
	for path in ["res://scenes/world/house.tscn", "res://scenes/world/garden.tscn"]:
		var text := FileAccess.get_file_as_string(path)
		_check(path + " builds walls from a TileMapLayer", text.contains("type=\"TileMapLayer\""))
		_check(path + " dropped the hardcoded wall rectangles",
			not text.contains("WallHorizontal") and not text.contains("FenceHorizontal"))
		_check(path + " wires the WorldGrid occupancy service", text.contains("world_grid"))


func _test_world_tileset_has_physics() -> void:
	var tileset: TileSet = load("res://assets/world_tileset.tres")
	_check("the world tileset loads", tileset != null)
	_check("solid tiles carry a physics layer", tileset.get_physics_layers_count() >= 1)


func _test_world_grid_maps_cells_and_footprints() -> void:
	var grid = load("res://scripts/world/world_grid.gd").new()
	_check("a pixel maps to its 16px cell", grid.to_cell(Vector2(40, 20)) == Vector2i(2, 1))
	_check("a cell maps back to its top-left pixel", grid.to_world(Vector2i(2, 1)) == Vector2(32, 16))
	var counter: Texture2D = load("res://assets/kitchen_counter.png")
	_check("a 48x28 sprite needs a 3x2 footprint", WorldGrid.footprint_of(counter) == Vector2i(3, 2))
	grid.free()


func _test_world_grid_tracks_occupancy() -> void:
	var grid = load("res://scripts/world/world_grid.gd").new()
	_check("an empty cell starts free", grid.is_free(Vector2i(5, 5), Vector2i(1, 1)))
	grid.register(Vector2i(5, 5), Vector2i(2, 1))
	_check("a registered cell is no longer free", not grid.is_free(Vector2i(5, 5), Vector2i(1, 1)))
	_check("an overlapping placement is blocked", not grid.is_free(Vector2i(6, 5), Vector2i(2, 2)))
	_check("a clear neighbour stays free", grid.is_free(Vector2i(5, 6), Vector2i(1, 1)))
	grid.release(Vector2i(5, 5), Vector2i(2, 1))
	_check("releasing frees the cells again", grid.is_free(Vector2i(5, 5), Vector2i(2, 1)))
	grid.free()


func _test_wall_objects_are_inspectable_fixtures() -> void:
	var house := FileAccess.get_file_as_string("res://scenes/world/house.tscn")
	_check("the window/portrait are inspectable wall fixtures",
		house.contains("scenes/world/wall_fixture.tscn"))
	var placeable := FileAccess.get_file_as_string("res://scenes/world/placeable_item.tscn")
	_check("furniture reuses the shared InteractableArea component",
		placeable.contains("scripts/world/interactable_area.gd"))


func _test_trash_pieces_block_their_tile() -> void:
	var piece := FileAccess.get_file_as_string("res://scenes/quest/trash_piece.tscn")
	_check("a trash piece has a collision body so it blocks its tile",
		piece.contains("name=\"Collision\""))


func _test_pickup_targets_the_nearest_pickable() -> void:
	var manager = load("res://scripts/autoload/interaction_manager.gd").new()
	get_root().add_child(manager)
	var player := Node2D.new()
	player.add_to_group("player")
	get_root().add_child(player)
	var inspect_only := _InspectOnly.new()
	inspect_only.global_position = Vector2(6, 0)
	get_root().add_child(inspect_only)
	var pickable := _Pickable.new()
	pickable.global_position = Vector2(24, 0)
	get_root().add_child(pickable)
	manager.register(inspect_only)
	manager.register(pickable)
	_check("interact targets the closest interactable",
		manager._nearest_interactable() == inspect_only)
	_check("pickup skips the closer non-pickable and finds the pickable one",
		manager._nearest_interactable(true) == pickable)
	manager.free()
	player.free()
	inspect_only.free()
	pickable.free()


func _test_mouse_has_a_walk_spritesheet() -> void:
	var sheet: Texture2D = load("res://assets/mouse_spritesheet.png")
	_check("the mouse has a 4-direction walk spritesheet (4 rows x 4 frames)",
		sheet.get_width() == FRAME_WIDTH * 4 and sheet.get_height() == FRAME_HEIGHT * 4)


func _test_cat_has_a_walk_spritesheet() -> void:
	var sheet: Texture2D = load("res://assets/cat_spritesheet.png")
	_check("Baby the cat has a 4-direction walk spritesheet (4 rows x 4 frames)",
		sheet.get_width() == FRAME_WIDTH * 4 and sheet.get_height() == FRAME_HEIGHT * 4)


# --- inventory -----------------------------------------------------------------

func _test_inventory_marks_quest_items() -> void:
	var inventory = load("res://scripts/autoload/inventory.gd").new()
	inventory.add_item("Trash Bag", "A fragrant bag of trash.", null, true)
	inventory.add_item("Cozy Rug", "It ties the room together.", null)
	_check("a quest item is flagged so it shows a star", inventory.items[0]["quest"] == true)
	_check("a normal item is not flagged as a quest item", inventory.items[1]["quest"] == false)
	inventory.free()


func _test_inventory_removes_delivered_items() -> void:
	var inventory = load("res://scripts/autoload/inventory.gd").new()
	inventory.add_item("Trash Bag", "A fragrant bag of trash.", null, true)
	inventory.remove_item("Trash Bag")
	_check("delivering the bag removes it from the inventory", inventory.items.is_empty())
	inventory.free()


# --- fonts and theme -----------------------------------------------------------

func _test_ui_font_is_a_crisp_bitmap() -> void:
	var theme: Theme = load("res://assets/ui_theme.tres")
	var font: Font = theme.default_font
	var size: int = theme.default_font_size
	_check("the UI uses the bitmap pixel font", font.get_font_name() == "font")
	var width: float = font.get_string_size("AAAA", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_check("the font renders 1:1 at its native size (stays crisp)", is_equal_approx(width, 24.0))
	_check("the unreadable tiny font is gone", not FileAccess.file_exists("res://assets/font_small.fnt"))


func _test_theme_gives_popups_a_background() -> void:
	var theme: Theme = load("res://assets/ui_theme.tres")
	var panel := theme.get_stylebox("panel", "Panel") as StyleBoxFlat
	_check("popups have an opaque panel background", panel != null and panel.bg_color.a > 0.9)
	_check("buttons keep a visible style", theme.get_stylebox("normal", "Button") != null)


# --- item popup ----------------------------------------------------------------

func _test_item_popup_reads_clearly() -> void:
	var popup = load("res://scenes/ui/item_popup.tscn").instantiate()
	get_root().add_child(popup)
	await process_frame
	var scroll := popup.get_node("Panel/DescriptionScroll") as ScrollContainer
	var label := scroll.get_node("DescriptionLabel") as Label
	popup.show_item("Kitchen Counter",
		"Where culinary dreams meet last night's unwashed dishes.",
		load("res://assets/kitchen_counter.png"))
	for _frame in 5:
		await process_frame
	_check("the description uses the main font, not a tiny one",
		label.get_theme_font("font").get_font_name() == "font")
	_check("a normal description fits the box without scrolling", label.size.y <= scroll.size.y)
	popup.free()
