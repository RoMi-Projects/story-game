extends QuestObject
## The garden bin. While the player is carrying trash it shows a marker and
## accepts the bag, completing the delivery step.

func on_primary() -> void:
	if QuestManager.is_carrying():
		QuestManager.deliver_trash()
		Inventory.remove_item(QuestManager.TRASH_ITEM)
		_flash_popup("You heave the trash in. Sweet, sweet freedom.")
	else:
		_toggle_info()


func _wants_marker() -> bool:
	return QuestManager.is_carrying()


func item_name() -> String:
	return "Trash Container"


func description() -> String:
	return "A big green bin. It hungers for garbage."
