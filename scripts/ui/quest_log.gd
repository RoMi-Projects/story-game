extends CanvasLayer
## Togglable panel listing the active quest and its current objective.
## Opened and closed with the "toggle_quests" button.

@onready var _panel: Panel = $Panel
@onready var _entries: VBoxContainer = $Panel/Entries


func _ready() -> void:
	QuestManager.changed.connect(_rebuild)
	_rebuild()
	close()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_quests"):
		_toggle()


func _toggle() -> void:
	if _panel.visible:
		close()
	else:
		_panel.visible = true


func close() -> void:
	_panel.visible = false


func _rebuild() -> void:
	for entry in _entries.get_children():
		entry.queue_free()
	if QuestManager.state == QuestManager.State.NOT_STARTED:
		_entries.add_child(_line("(no active quests)", Color.WHITE))
		return
	_entries.add_child(_line(QuestManager.TITLE, Color(0.84, 0.7, 0.38, 1)))
	if QuestManager.is_completed():
		_entries.add_child(_line("Completed!", Color(0.55, 0.8, 0.55, 1)))
	else:
		_entries.add_child(_line(QuestManager.objective_text(), Color.WHITE))


func _line(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(180, 0)
	return label
