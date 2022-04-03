extends Control

onready var board = $BoardContainer
const tile_template = preload("res://prefabs/tile.tscn")
const torus_template = preload("res://prefabs/torus.tscn")

var board_size: Vector2
var active_torus: Node



func _ready():  # TMP, used to test initialisation
	init()


func init(board_size: Vector2 = Vector2(10, 8), player_pieces: int = 20):
	self.board_size = board_size
	board.columns = board_size.x
	
	_init_tiles()
	_init_toruses(player_pieces)


func _get_child_at_pos(x: int, y: int):
	return board.get_child(y * board_size.x + x)


func _get_child_at_idx(idx: int):
	return board.get_child(idx)


func _init_tiles():
	for i in range(board_size.x * board_size.y):
		var new_tile = tile_template.instance().init(Vector3(i % int(board_size.x), int(i / board_size.x), 0))
		board.add_child(new_tile)


func _init_toruses(player_pieces: int):
	for i in range(player_pieces):
		var player1_torus = torus_template.instance().init(self, _get_child_at_idx(i), 0, Torus.COLORS.RED)
		var player2_torus = torus_template.instance().init(self, _get_child_at_idx(board_size.x * board_size.y - 1 - i), 1, Torus.COLORS.BLUE)
		
		_get_child_at_idx(i).set_slot(player1_torus)
		_get_child_at_idx(board_size.x * board_size.y - 1 - i).set_slot(player2_torus)


# After picking up torus, move it to top of the tree, so it won't get covered
# by other sprites. After putting down, place back on original position, unless
# it was a new tile, in this case move to it
func _torus_pickup(torus: Node):
	self.active_torus = torus
	torus.current_tile.del_piece()
	add_child(torus)


func _torus_putdown(torus: Node):
	remove_child(self.active_torus)

	var dest_tile_pos = (get_global_mouse_position() - rect_global_position) / (get_child(0).get_child(0).rect_size * rect_scale)
	var x = int(dest_tile_pos.x)
	var y = int(dest_tile_pos.y)
	
	if 0 > x or x >= board_size.x or 0 > y or y >= board_size.y:
		self.active_torus.current_tile.set_slot(self.active_torus)
		return
	
	var target_tile: Tile = _get_child_at_pos(x, y)
	if torus.should_move_torus(self.active_torus.current_tile, target_tile):
		var is_colliding = target_tile.has_piece()
		self._get_child_at_pos(x, y).set_slot(self.active_torus)
		torus.make_move(self.active_torus.current_tile, target_tile, is_colliding)
		return
	
	self.torus_source_slot.add_child(self.active_torus)
