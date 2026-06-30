extends Node
## Build Mode: a developer overlay that draws the world's 16x16 tile grid with
## column/row indices, toggled with the `toggle_build_mode` key. It exists to make
## hand-placing furniture in the `.tscn` files easy: read a cell's column and row off
## the grid to choose a node's `position`.
##
## Registered as an autoload so the overlay persists across scene changes with no
## per-scene wiring. The overlay is a screen-space `CanvasLayer`, which lines up 1:1
## with world tiles only because the camera shows the whole 320x180 world without
## scrolling or zoom.

const TILE := 16
const OVERLAY_LAYER := 128
const LINE_WIDTH := 1.0
const LINE_COLOR := Color(0.2, 0.9, 1.0, 0.35)
const LABEL_COLOR := Color(1.0, 1.0, 0.4, 0.9)
const LABEL_MARGIN := 2.0

var _enabled := false
var _layer: CanvasLayer = null
var _overlay: Control = null
var _font: Font = null
var _font_size := 7


func _ready() -> void:
	_ensure_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		toggle()


func toggle() -> void:
	set_enabled(not _enabled)


func set_enabled(value: bool) -> void:
	_enabled = value
	_ensure_overlay()
	_layer.visible = _enabled
	_overlay.queue_redraw()


func is_enabled() -> bool:
	return _enabled


func grid_is_visible() -> bool:
	return _layer != null and _layer.visible


func _load_font() -> void:
	var theme := load("res://assets/ui_theme.tres") as Theme
	_font = theme.default_font
	_font_size = theme.default_font_size


func _ensure_overlay() -> void:
	if _layer != null:
		return
	_load_font()
	_build_overlay()


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = OVERLAY_LAYER
	_layer.visible = false
	add_child(_layer)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_grid)
	_layer.add_child(_overlay)


func _draw_grid() -> void:
	var size := _overlay.size
	var columns := int(ceil(size.x / TILE))
	var rows := int(ceil(size.y / TILE))
	_draw_lines(size, columns, rows)
	_draw_indices(columns, rows)


func _draw_lines(size: Vector2, columns: int, rows: int) -> void:
	for column in columns + 1:
		var x := float(column * TILE)
		_overlay.draw_line(Vector2(x, 0.0), Vector2(x, size.y), LINE_COLOR, LINE_WIDTH)
	for row in rows + 1:
		var y := float(row * TILE)
		_overlay.draw_line(Vector2(0.0, y), Vector2(size.x, y), LINE_COLOR, LINE_WIDTH)


func _draw_indices(columns: int, rows: int) -> void:
	for column in columns:
		var top := Vector2(column * TILE + LABEL_MARGIN, _font_size)
		_overlay.draw_string(_font, top, str(column),
			HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, LABEL_COLOR)
	for row in rows:
		var left := Vector2(LABEL_MARGIN, row * TILE + _font_size)
		_overlay.draw_string(_font, left, str(row),
			HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, LABEL_COLOR)
