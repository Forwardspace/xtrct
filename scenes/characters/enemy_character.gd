extends Sprite2D

var peer_id = 0
var is_ready = false

var move_target = Vector2(0, 0)
var move_path = "null"

var register_contents = []

@export var player_colors: Array = [
	Color.HOT_PINK, Color.AQUAMARINE, Color.CHOCOLATE, 
	Color.DARK_MAGENTA, Color.MEDIUM_BLUE, Color.GOLD,
	Color.CRIMSON, Color.INDIGO, Color.ORANGE_RED
]
@export var cell_position: Vector2 = Vector2(5, 3)
@export var environment: Node2D = null
@export var player: Sprite2D = null

const CELL_SIZE = 32
func try_move_one_direction(direction):
	var roomCurrent = environment.get_room_by_cell_point(cell_position)
	var roomNext = environment.get_room_by_cell_point(cell_position + direction)
	
	if roomNext == null:
		return false	 # Invalid move direction - cell not in room
	
	if roomCurrent != roomNext:
		# We would be switching rooms - are we landing in a doorway square?
		if environment.get_doorway_by_cell_point(cell_position + direction) == null:
			# No - can't move (wall)
			# Still, return true ("waste" this movement step)
			return true

	cell_position += direction
	return true

func move_one():
	if move_target == null:
		return
		
	var try_move_x = func():
		if cell_position.x - move_target.x > 0.2:
			return try_move_one_direction(Vector2(-1, 0))
		elif move_target.x - cell_position.x > 0.2:
			return try_move_one_direction(Vector2(1, 0))
		return false

	var try_move_y = func():
		if cell_position.y - move_target.y > 0.2:
			return try_move_one_direction(Vector2(0, -1))
		elif move_target.y - cell_position.y > 0.2:
			return try_move_one_direction(Vector2(0, 1))
		return false
	
	if move_path == "xfirst":
		if not try_move_x.call():
			try_move_y.call()
	else:
		if not try_move_y.call():
			try_move_x.call()
	
	position = cell_position * CELL_SIZE + Vector2(16, 16)

func _ready():
	self_modulate = player_colors[peer_id % player_colors.size()]
	
func _process(delta):
	position = cell_position * CELL_SIZE + Vector2(16, 16)
	
	# Check if we enemy is in the fog of war
	# if so, it isn't visible
	if player.position.distance_to(position) > player.visibility_distance:
		visible = false
	else:
		visible = true
