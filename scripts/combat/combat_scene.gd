extends Control
class_name CombatScene
## Shared scaffolding for a one-action creature encounter: seeding the dice,
## narrating a line with a beat between messages, locking the action menu while a
## turn plays out, and the routes back to the garden (win / escape) or home to the
## house (a loss). Concrete encounters — the mouse, the cat — wire their own
## buttons and outcomes on top. Both keep a `MessagePanel/Message` label and a
## `MenuPanel` so this base can drive them.

const GARDEN := "res://scenes/world/garden.tscn"
const HOUSE := "res://scenes/world/house.tscn"
const HOUSE_SPAWN := Vector2(44, 118)
const BEAT_SECONDS := 1.1

@onready var _message: Label = $MessagePanel/Message
@onready var _menu: Panel = $MenuPanel

var _rng := RandomNumberGenerator.new()
var _busy := false


func _ready() -> void:
	_rng.randomize()


func _take_player_turn(action: Callable) -> void:
	if _busy:
		return
	_busy = true
	_menu.visible = false
	await action.call()


func _announce(text: String) -> void:
	_message.text = text
	await get_tree().create_timer(BEAT_SECONDS).timeout


func _lose_bag() -> void:
	Inventory.remove_item(QuestManager.TRASH_ITEM)
	QuestManager.drop_bag()


func _return_to_garden() -> void:
	get_tree().change_scene_to_file.call_deferred(GARDEN)


func _retreat_to_house(enemy: String) -> void:
	GameState.flag_loss(enemy)
	GameState.set_spawn(HOUSE_SPAWN)
	get_tree().change_scene_to_file.call_deferred(HOUSE)
