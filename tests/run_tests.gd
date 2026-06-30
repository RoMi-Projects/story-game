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


func _initialize() -> void:
	_test_quest_advances_through_every_step()
	_test_quest_ignores_out_of_order_steps()
	_test_pieces_are_counted_once_and_remembered()
	_test_world_holds_exactly_enough_pieces()
	_test_desi_has_a_walk_spritesheet()
	_test_character_faces_its_movement_direction()
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
	var quest = load("res://scripts/quest_manager.gd").new()
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
	var quest = load("res://scripts/quest_manager.gd").new()
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
	var placed := _count_pieces("res://scenes/House.tscn") + _count_pieces("res://scenes/Garden.tscn")
	var quest = load("res://scripts/quest_manager.gd").new()
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
	var quest = load("res://scripts/quest_manager.gd").new()
	quest.accept()
	quest.take_bag()
	quest.collect_piece("house_1")
	quest.collect_piece("house_1")
	_check("the same piece is only counted once", quest.pieces_collected() == 1)
	_check("a bagged piece stays remembered across scenes", quest.is_piece_collected("house_1"))
	quest.free()


# --- inventory -----------------------------------------------------------------

func _test_inventory_marks_quest_items() -> void:
	var inventory = load("res://scripts/inventory.gd").new()
	inventory.add_item("Trash Bag", "A fragrant bag of trash.", null, true)
	inventory.add_item("Cozy Rug", "It ties the room together.", null)
	_check("a quest item is flagged so it shows a star", inventory.items[0]["quest"] == true)
	_check("a normal item is not flagged as a quest item", inventory.items[1]["quest"] == false)
	inventory.free()


func _test_inventory_removes_delivered_items() -> void:
	var inventory = load("res://scripts/inventory.gd").new()
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
	var popup = load("res://scenes/ItemPopup.tscn").instantiate()
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
