class_name Tile
extends PanelContainer

onready var slot = $TorusSlot

var is_steppable = true
var tile_pos: Vector3  # Z - elevation, from -2 to +2, total 5 levels



func init(tile_pos: Vector3):
	self.tile_pos = tile_pos
	return self


func get_pos() -> Vector3:
	return tile_pos


func is_steppable() -> bool:
	return is_steppable


func has_piece() -> bool:
	return slot.get_child_count() != 0


func get_piece():
	return slot.get_child(0)


func set_slot(torus: Control):
	if has_piece():
		slot.remove_child(slot.get_child(0))
	
	slot.add_child(torus)
