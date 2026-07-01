extends CombatScene
## The Pokemon-style mouse encounter.
##
## The player gets one action: throw the trash bag (only while carrying it),
## scream, or run. If it doesn't resolve the fight in their favour the mouse
## takes a turn and either charges (the player loses and flees home) or wanders
## off. The dice live in `CombatRules`; this scene just narrates and applies the
## outcome. The message beat and the routes home come from `CombatScene`.

@onready var _throw_button: Button = $MenuPanel/ThrowButton
@onready var _scream_button: Button = $MenuPanel/ScreamButton
@onready var _run_button: Button = $MenuPanel/RunButton


func _ready() -> void:
	super()
	_throw_button.pressed.connect(_on_throw)
	_scream_button.pressed.connect(_on_scream)
	_run_button.pressed.connect(_on_run)
	_throw_button.visible = QuestManager.is_carrying()
	_message.text = "A garden mouse darts out and blocks your path!"


func _on_throw() -> void:
	await _take_player_turn(_throw)


func _on_scream() -> void:
	await _take_player_turn(_scream)


func _on_run() -> void:
	await _take_player_turn(_run)


func _throw() -> void:
	await _announce("You hurl the trash bag at the mouse!")
	if CombatRules.throw_hits(_rng):
		await _announce("Direct hit! The mouse bolts, and you scoop your bag back up.")
		_win()
	else:
		_lose_bag()
		await _announce("You miss! The bag splits and your trash spills back across the garden.")
		await _mouse_turn()


func _scream() -> void:
	await _announce("You scream at the top of your lungs!")
	if CombatRules.scream_scares_mouse(_rng):
		await _announce("The mouse panics and scurries away.")
		_win()
	else:
		await _announce("The mouse just twitches its whiskers, unimpressed.")
		await _mouse_turn()


func _run() -> void:
	await _announce("You turn and bolt!")
	if CombatRules.run_escapes(_rng):
		await _announce("You get away clean.")
		_win()
	else:
		await _announce("The mouse cuts you off!")
		await _mouse_turn()


func _mouse_turn() -> void:
	if CombatRules.mouse_charges(_rng):
		await _announce("The mouse charges — you flee all the way home!")
		GameState.suppress_mouse()
		_retreat_to_house("mouse")
	else:
		await _announce("The mouse loses interest and vanishes into the grass.")
		_win()


func _win() -> void:
	GameState.suppress_mouse()
	_return_to_garden()
