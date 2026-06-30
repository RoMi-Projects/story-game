extends QuestObject
## A loose piece of trash hidden in the world. It shows no marker, so the player
## has to spot it. While carrying the bag the primary button bags it: the piece
## leaves the world and the counter goes up. Bagged pieces stay gone across scene
## changes, keyed by `piece_id`.

@export var piece_id: String

func _ready() -> void:
	if QuestManager.is_piece_collected(piece_id):
		queue_free()
		return
	super._ready()


func on_primary() -> void:
	if QuestManager.is_carrying():
		_bag_it()
	else:
		_toggle_info()


func _bag_it() -> void:
	var popup := _popup()
	if popup != null:
		popup.close()
	InteractionManager.unregister(self)
	QuestManager.collect_piece(piece_id)
	queue_free()


func item_name() -> String:
	return "Trash"


func description() -> String:
	return "A bit of litter. Grab a bag from the kitchen, then come back for it."


func _wants_marker() -> bool:
	return false
