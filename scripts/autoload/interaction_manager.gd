extends Node
## Routes the primary and secondary buttons to the nearest interactable.
##
## Interactables (NPCs, furniture) register themselves while the player is
## within their interaction area. Each frame the player presses a button, this
## manager forwards it to the closest one, so two nearby objects never both
## react to the same press.
##
## An interactable must expose `on_primary()` and `global_position`; an
## `on_secondary()` is optional (e.g. furniture can be picked up, Desi cannot).

var _in_range: Array[Node] = []
var _player: Node2D = null


func register(interactable: Node) -> void:
	if interactable not in _in_range:
		_in_range.append(interactable)


func unregister(interactable: Node) -> void:
	_in_range.erase(interactable)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		var target := _nearest_interactable()
		if target != null:
			target.on_primary()
	elif Input.is_action_just_pressed("pickup"):
		# Pick the nearest object that can actually be picked up, so a non-pickable
		# object standing between you and the furniture (a trash piece, a wall
		# fixture) doesn't swallow the press.
		var target := _nearest_interactable(true)
		if target != null:
			target.on_secondary()


func _nearest_interactable(must_pick_up := false) -> Node:
	_drop_freed_interactables()
	var player := _get_player()
	var nearest: Node = null
	var nearest_distance := INF
	for interactable in _in_range:
		if must_pick_up and not interactable.has_method("on_secondary"):
			continue
		if player == null:
			return interactable
		var distance: float = player.global_position.distance_squared_to(interactable.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = interactable
	return nearest


func _drop_freed_interactables() -> void:
	_in_range = _in_range.filter(func(item): return is_instance_valid(item))


func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player
