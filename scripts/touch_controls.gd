extends CanvasLayer
## On-screen directional buttons (a touch D-pad).
##
## Each button presses and releases a movement input action while held, so the
## player script reacts to touch exactly as it reacts to the keyboard. This also
## makes the game playable on phones and tablets.

@onready var _action_for_button := {
	$DPad/Up: "move_up",
	$DPad/Down: "move_down",
	$DPad/Left: "move_left",
	$DPad/Right: "move_right",
	$DPad/Action: "interact",
}


func _ready() -> void:
	for button in _action_for_button:
		_connect_button(button, _action_for_button[button])


func _connect_button(button: BaseButton, action: StringName) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
