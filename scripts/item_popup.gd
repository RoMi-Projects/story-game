extends CanvasLayer
## Centered popup that shows a picked-at object: its picture, name, and a fun
## description. Furniture opens and closes it through the "item_popup" group.

@onready var _panel: Panel = $Panel
@onready var _image: TextureRect = $Panel/Image
@onready var _name_label: Label = $Panel/NameLabel
@onready var _description_label: Label = $Panel/DescriptionLabel


func _ready() -> void:
	add_to_group("item_popup")
	close()


func show_item(item_name: String, description: String, texture: Texture2D) -> void:
	_image.texture = texture
	_name_label.text = item_name
	_description_label.text = description
	_panel.visible = true


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible
