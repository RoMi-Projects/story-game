extends QuestObject
## The garden bin. Once every loose piece of trash has been bagged it shows a
## marker and accepts the full bag, completing the delivery step.

func on_primary() -> void:
	if not QuestManager.is_carrying():
		_toggle_info()
		return
	if QuestManager.all_pieces_collected():
		QuestManager.deliver_trash()
		Inventory.remove_item(QuestManager.TRASH_ITEM)
		_flash_popup("You heave the full bag in. Sweet, sweet freedom.")
	else:
		var remaining := QuestManager.TRASH_TOTAL - QuestManager.pieces_collected()
		var pieces := "piece" if remaining == 1 else "pieces"
		_flash_popup("The bag isn't full yet. %d more %s to find." % [remaining, pieces])


func _wants_marker() -> bool:
	return QuestManager.is_carrying() and QuestManager.all_pieces_collected()


func item_name() -> String:
	return "Trash Container"


func description() -> String:
	return "A big green bin. It hungers for garbage."
