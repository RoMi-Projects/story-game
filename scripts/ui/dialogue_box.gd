extends CanvasLayer
## A message box pinned to the bottom of the screen.
##
## Shows a speaker's portrait, name, and a line of text. NPCs open and close it
## through the "dialogue_box" group, so they don't need a direct reference.

@onready var _panel: Panel = $Panel
@onready var _portrait: TextureRect = $Panel/Portrait
@onready var _name_label: Label = $Panel/NameLabel
@onready var _message_label: Label = $Panel/MessageLabel


func _ready() -> void:
	add_to_group("dialogue_box")
	close()


func open(speaker_name: String, portrait: Texture2D, message: String) -> void:
	_name_label.text = speaker_name
	_portrait.texture = portrait
	_message_label.text = message
	_panel.visible = true


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible
