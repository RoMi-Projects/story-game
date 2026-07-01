extends Node
class_name WorldGrid
## Per-scene occupancy service for the 16px world grid.
##
## It knows which cells the walls block (read from the scene's wall `TileMapLayer`)
## and which cells objects have claimed. A griddable object snaps to a cell and
## registers its footprint here; a future move/placement mode asks `is_free()`
## before dropping something. Objects find the service via the "world_grid" group.
## Everything is lazy, so call order between objects and this node does not matter.

const TILE := 16

var _blocked := {}      # Vector2i -> owner Node (claimed by objects)
var _wall_cells := {}   # Vector2i -> true (from the wall TileMapLayer)
var _walls_read := false


func to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


func to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE, cell.y * TILE)


func snap(pos: Vector2) -> Vector2:
	return to_world(to_cell(pos))


func footprint_of(texture: Texture2D) -> Vector2i:
	if texture == null:
		return Vector2i.ONE
	var size := texture.get_size()
	return Vector2i(maxi(1, ceili(size.x / TILE)), maxi(1, ceili(size.y / TILE)))


func cells_for(origin: Vector2i, size: Vector2i) -> Array:
	var cells := []
	for dx in maxi(1, size.x):
		for dy in maxi(1, size.y):
			cells.append(origin + Vector2i(dx, dy))
	return cells


func is_free(origin: Vector2i, size: Vector2i) -> bool:
	_ensure_walls()
	for cell in cells_for(origin, size):
		if _wall_cells.has(cell) or _blocked.has(cell):
			return false
	return true


func register(origin: Vector2i, size: Vector2i, owner: Node = null) -> void:
	for cell in cells_for(origin, size):
		_blocked[cell] = owner


func release(origin: Vector2i, size: Vector2i) -> void:
	for cell in cells_for(origin, size):
		_blocked.erase(cell)


func blocked_cells() -> Array:
	_ensure_walls()
	return _wall_cells.keys() + _blocked.keys()


func _ensure_walls() -> void:
	if _walls_read:
		return
	_walls_read = true
	var walls := _find_walls()
	if walls != null:
		for cell in walls.get_used_cells():
			_wall_cells[cell] = true


func _find_walls() -> TileMapLayer:
	var root := get_parent()
	if root == null:
		return null
	for child in root.get_children():
		if child is TileMapLayer:
			return child
	return null
