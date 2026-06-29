extends Node
## The single "Take Out the Trash" quest, modelled as a small state machine.
##
## Every quest object (Desi, the trash can, the garden container) and the player
## react to `state` and refresh when `changed` is emitted. Written so more
## quests can be added later, but only this one ships now.

signal changed

enum State { NOT_STARTED, ACCEPTED, CARRYING, DELIVERED, COMPLETED }

const TITLE := "Take Out the Trash"
const TRASH_ITEM := "Trash Bag"

var state: State = State.NOT_STARTED


func accept() -> void:
	_advance(State.ACCEPTED, State.NOT_STARTED)


func collect_trash() -> void:
	_advance(State.CARRYING, State.ACCEPTED)


func deliver_trash() -> void:
	_advance(State.DELIVERED, State.CARRYING)


func turn_in() -> void:
	_advance(State.COMPLETED, State.DELIVERED)


func _advance(next_state: State, required_state: State) -> void:
	if state != required_state:
		return
	state = next_state
	changed.emit()


func is_carrying() -> bool:
	return state == State.CARRYING


func is_active() -> bool:
	return state != State.NOT_STARTED and state != State.COMPLETED


func is_completed() -> bool:
	return state == State.COMPLETED


func objective_text() -> String:
	match state:
		State.ACCEPTED:
			return "Grab the bag from the kitchen trash can."
		State.CARRYING:
			return "Carry the trash to the container in the garden."
		State.DELIVERED:
			return "Return to Desi."
		State.COMPLETED:
			return "Done."
		_:
			return ""
