extends CanvasLayer
## Togglable panel that lists the items the player has collected.
##
## Opened and closed with the "toggle_inventory" button. Rebuilds its list
## whenever the inventory changes.

const STAR := preload("res://assets/star.png")

@onready var _panel: Panel = $Panel
@onready var _items: VBoxContainer = $Panel/Items


func _ready() -> void:
	Inventory.changed.connect(_rebuild_list)
	_rebuild_list()
	close()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		_toggle()


func _toggle() -> void:
	if _panel.visible:
		close()
	else:
		_panel.visible = true


func close() -> void:
	_panel.visible = false


func _rebuild_list() -> void:
	for entry in _items.get_children():
		entry.queue_free()
	if Inventory.items.is_empty():
		_items.add_child(_entry_label("(empty)"))
		return
	for item in Inventory.items:
		_items.add_child(_entry_row(item))


func _entry_row(item: Dictionary) -> Control:
	if item.get("quest", false):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row.add_child(_star_icon())
		row.add_child(_entry_label(item["name"]))
		return row
	return _entry_label("- " + item["name"])


func _star_icon() -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = STAR
	icon.custom_minimum_size = Vector2(10, 10)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _entry_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label
