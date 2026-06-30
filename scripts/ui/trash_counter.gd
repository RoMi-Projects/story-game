extends CanvasLayer
## A small heads-up counter showing how much trash has been bagged. Visible only
## while the player is carrying the bag and hunting for loose pieces.

@onready var _panel: Panel = $Panel
@onready var _count: Label = $Panel/Count


func _ready() -> void:
	QuestManager.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_panel.visible = QuestManager.is_carrying()
	_count.text = "%d / %d" % [QuestManager.pieces_collected(), QuestManager.TRASH_TOTAL]
