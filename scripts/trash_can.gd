extends QuestObject
## The kitchen trash can. Normally inspectable; while the quest is at the
## collect step it shows a marker and hands over a bag of trash.

const BAG := preload("res://assets/trash_bag.png")

func on_primary() -> void:
	if QuestManager.state == QuestManager.State.ACCEPTED:
		QuestManager.collect_trash()
		Inventory.add_item(QuestManager.TRASH_ITEM,
			"A fragrant bag of trash. Desi wants it gone.", BAG, true)
		_flash_popup("You grab a fragrant bag of trash. Lovely.")
	else:
		_toggle_info()


func _wants_marker() -> bool:
	return QuestManager.state == QuestManager.State.ACCEPTED


func item_name() -> String:
	return "Trash Can"


func description() -> String:
	return "Desi's mortal enemy. Something must be done about it."
