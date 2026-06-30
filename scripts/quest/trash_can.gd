extends QuestObject
## The kitchen trash can. While the quest is at the accept step it shows a marker
## and hands the player an empty bag to start the hunt for loose trash.

const BAG := preload("res://assets/empty_bag.png")

func on_primary() -> void:
	if QuestManager.state == QuestManager.State.ACCEPTED:
		QuestManager.take_bag()
		Inventory.add_item(QuestManager.TRASH_ITEM,
			"An empty bag, ready to be filled with trash.", BAG, true)
		_flash_popup("You grab an empty bag. Now hunt down the mess.")
	else:
		_toggle_info()


func _wants_marker() -> bool:
	return QuestManager.state == QuestManager.State.ACCEPTED


func item_name() -> String:
	return "Trash Can"


func description() -> String:
	return "Desi's mortal enemy. Something must be done about it."
