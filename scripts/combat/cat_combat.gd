extends CombatScene
## Baby's encounter. The player gets one action: pet her (a slim chance she is
## charmed and lets you go), call her over (bravado — no real edge in a one-shot
## fight), or back away and leave. If the action doesn't win or escape, Baby takes
## a turn: she either loses interest or shreds your trash bag, which sends you
## home just like a lost mouse fight. The dice live in `CombatRules`; the message
## beat and the routes home come from `CombatScene`.

const HAPPY := preload("res://assets/cat_battle_happy.png")

@onready var _enemy_sprite: TextureRect = $EnemySprite
@onready var _pet_button: Button = $MenuPanel/PetButton
@onready var _call_button: Button = $MenuPanel/CallButton
@onready var _go_button: Button = $MenuPanel/GoButton


func _ready() -> void:
	super()
	_pet_button.pressed.connect(_on_pet)
	_call_button.pressed.connect(_on_call)
	_go_button.pressed.connect(_on_go)
	_message.text = "Baby the cat glares at you, tail thrashing."


func _on_pet() -> void:
	await _take_player_turn(_pet)


func _on_call() -> void:
	await _take_player_turn(_call)


func _on_go() -> void:
	await _take_player_turn(_go)


func _pet() -> void:
	await _announce("You slowly reach out to pet Baby...")
	if CombatRules.cat_pet_succeeds(_rng):
		_enemy_sprite.texture = HAPPY
		await _announce("Baby purrs and headbutts your hand. Meow! You part as friends.")
		_return_to_garden()
	else:
		await _announce("Baby swats your hand away with a hiss.")
		await _cat_turn()


func _call() -> void:
	if CombatRules.cat_approaches(_rng):
		await _announce("\"Here, Baby!\" She pads a step closer, ears flat.")
	else:
		await _announce("\"Here, Baby!\" She ignores you completely.")
	await _cat_turn()


func _go() -> void:
	await _announce("You back away slowly and leave Baby to her garden.")
	_return_to_garden()


func _cat_turn() -> void:
	if QuestManager.is_carrying() and CombatRules.cat_breaks_bag(_rng):
		_lose_bag()
		await _announce("Baby pounces and shreds your trash bag! You retreat home.")
		_retreat_to_house("cat")
	else:
		await _announce("Baby loses interest and slinks into the bushes.")
		_return_to_garden()
