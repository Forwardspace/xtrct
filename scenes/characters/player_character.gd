extends Sprite2D

@export var local_state: Node2D = null
@export var remote_state: Node2D = null
@export var environment: Node2D = null
@export var fog_of_war_effect: ColorRect = null;
@export var player_colors: Array = [
	Color.HOT_PINK, Color.AQUAMARINE, Color.CHOCOLATE, 
	Color.DARK_MAGENTA, Color.MEDIUM_BLUE, Color.GOLD,
	Color.CRIMSON, Color.INDIGO, Color.ORANGE_RED
]

@export var cell_position: Vector2 = Vector2(0, 0)
@export var visibility_distance: float = 96

const CELL_SIZE = 32

var queuedMoveTargetCell = null
var queuedMoveTargetWay = "xfirst"

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
	if queuedMoveTargetCell == null:
		return
		
	var try_move_x = func():
		if cell_position.x - queuedMoveTargetCell.x > 0.2:
			return try_move_one_direction(Vector2(-1, 0))
		elif queuedMoveTargetCell.x - cell_position.x > 0.2:
			return try_move_one_direction(Vector2(1, 0))
		return false

	var try_move_y = func():
		if cell_position.y - queuedMoveTargetCell.y > 0.2:
			return try_move_one_direction(Vector2(0, -1))
		elif queuedMoveTargetCell.y - cell_position.y > 0.2:
			return try_move_one_direction(Vector2(0, 1))
		return false
	
	if queuedMoveTargetWay == "xfirst":
		if not try_move_x.call():
			try_move_y.call()
	else:
		if not try_move_y.call():
			try_move_x.call()
	
	position = cell_position * CELL_SIZE + Vector2(16, 16)
	update_movement_indicator()

var rng = RandomNumberGenerator.new()
func _ready():
	self_modulate = player_colors[multiplayer.get_unique_id() % player_colors.size()]
	
	local_state.execute_step_basic_move_once.connect(move_one)
	fog_of_war_effect.material.set_shader_parameter("distace_threshold", visibility_distance)

func update_movement_indicator():
	if queuedMoveTargetWay == "xfirst":
		$movement_indicator.points[0] = Vector2(0, 0)
		$movement_indicator.points[1] = Vector2(queuedMoveTargetCell.x * CELL_SIZE - position.x + 16, 0)
		$movement_indicator.points[2] = Vector2(queuedMoveTargetCell.x * CELL_SIZE - position.x + 16, queuedMoveTargetCell.y * CELL_SIZE - position.y + 16)
	else:
		$movement_indicator.points[0] = Vector2(0, 0)
		$movement_indicator.points[1] = Vector2(0, queuedMoveTargetCell.y * CELL_SIZE - position.y + 16)
		$movement_indicator.points[2] = Vector2(queuedMoveTargetCell.x * CELL_SIZE - position.x + 16, queuedMoveTargetCell.y * CELL_SIZE - position.y + 16)
	
	if queuedMoveTargetCell != cell_position:
		$movement_target_indicator.visible = true
		$movement_target_indicator.position = queuedMoveTargetCell * CELL_SIZE - position + Vector2(16, 16)
	else:
		$movement_target_indicator.visible = false

func _unhandled_input(event):
	if local_state.is_ready or remote_state.game_stage != "record":
		return 	# Can't change move when ready or while executing
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index != 1 and event.button_index != 2:
			# Only relevant buttons are left and right click
			return
		
		var mousePosRel = get_parent().to_local(get_viewport().get_mouse_position())
		# Avoids off by one error when taking the floor of a negative number
		if mousePosRel.x < 0:
			mousePosRel.x -= CELL_SIZE
		if mousePosRel.y < 0:
			mousePosRel.y -= CELL_SIZE
		
		var cellCoordsRel = mousePosRel
		cellCoordsRel.x = int(cellCoordsRel.x - int(cellCoordsRel.x) % CELL_SIZE)
		cellCoordsRel.y = int(cellCoordsRel.y - int(cellCoordsRel.y) % CELL_SIZE)
		
		queuedMoveTargetCell = Vector2(int(cellCoordsRel.x / CELL_SIZE), int(cellCoordsRel.y / CELL_SIZE))

		if event.button_index == 2:
			queuedMoveTargetWay = "xfirst"
		elif event.button_index == 1:
			queuedMoveTargetWay = "yfirst"
			
		update_movement_indicator()
			
		remote_state.on_move_target_change.rpc(queuedMoveTargetCell, queuedMoveTargetWay)

func _process(delta):
	if multiplayer.get_unique_id() == 0:
		visible = false
	
	position = cell_position * CELL_SIZE + Vector2(16, 16)
	
	fog_of_war_effect.material.set_shader_parameter("player_pos", position)
