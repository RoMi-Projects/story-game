extends Node
## The single "Take Out the Trash" quest, modelled as a small state machine.
##
## The player accepts the quest from Desi, grabs an empty bag from the kitchen,
## hunts down every loose piece of trash in the house and garden, throws the full
## bag in the garden bin, then returns to Desi. Quest objects and the player react
## to `state` (and the collected count) and refresh when `changed` is emitted.

signal changed

enum State { NOT_STARTED, ACCEPTED, COLLECTING, DELIVERED, COMPLETED }

const TITLE := "Take Out the Trash"
const TRASH_ITEM := "Trash Bag"
const TRASH_TOTAL := 8

var state: State = State.NOT_STARTED

# Ids of the trash pieces already bagged. Lives on this autoload so a piece stays
# gone after the player walks between the house and the garden.
var _collected_pieces := {}


func accept() -> void:
	_advance(State.ACCEPTED, State.NOT_STARTED)


func take_bag() -> void:
	_advance(State.COLLECTING, State.ACCEPTED)


func collect_piece(piece_id: String) -> void:
	if state != State.COLLECTING or _collected_pieces.has(piece_id):
		return
	_collected_pieces[piece_id] = true
	changed.emit()


func deliver_trash() -> void:
	if not all_pieces_collected():
		return
	_advance(State.DELIVERED, State.COLLECTING)


func drop_bag() -> void:
	# Throwing the bag at the mouse and missing spills the haul: every collected
	# piece returns to the world and the player must grab a fresh bag.
	if state != State.COLLECTING:
		return
	_collected_pieces.clear()
	state = State.ACCEPTED
	changed.emit()


func turn_in() -> void:
	_advance(State.COMPLETED, State.DELIVERED)


func _advance(next_state: State, required_state: State) -> void:
	if state != required_state:
		return
	state = next_state
	changed.emit()


func is_piece_collected(piece_id: String) -> bool:
	return _collected_pieces.has(piece_id)


func pieces_collected() -> int:
	return _collected_pieces.size()


func all_pieces_collected() -> bool:
	return pieces_collected() >= TRASH_TOTAL


func is_carrying() -> bool:
	return state == State.COLLECTING


func is_active() -> bool:
	return state != State.NOT_STARTED and state != State.COMPLETED


func is_completed() -> bool:
	return state == State.COMPLETED


func objective_text() -> String:
	match state:
		State.ACCEPTED:
			return "Grab an empty bag from the kitchen."
		State.COLLECTING:
			if all_pieces_collected():
				return "Throw the full bag in the garden bin."
			return "Find the trash: %d/%d." % [pieces_collected(), TRASH_TOTAL]
		State.DELIVERED:
			return "Return to Desi."
		State.COMPLETED:
			return "Done."
		_:
			return ""
