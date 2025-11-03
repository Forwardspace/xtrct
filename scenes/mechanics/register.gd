extends Sprite2D

signal attached_action_changed

@export var reg_index: int = 0
@export var is_enabled: bool = false
@export var local_state: Node2D = null

var assigned_action = null

func assign_action(action):
	if assigned_action != null or local_state.is_ready or not is_enabled:
		# Cannot attach - space already occupied,
		# or player ended the turn, or this register is disabled
		return false
	
	assigned_action = action
	action.global_position = global_position
	
	attached_action_changed.emit(action.type, reg_index)
	return true
	
func detach_action():
	assigned_action = null
	attached_action_changed.emit(null, reg_index)

func _process(delta):
	# Essentially, disables dragging actions away from this register when
	# the player ended their turn
	if local_state.is_ready or not is_enabled:
		$ColorRect.mouse_filter = 0	# STOP
	else:
		$ColorRect.mouse_filter = 2	# IGNORE
		
	if not is_enabled:
		modulate = Color(0.165, 0.518, 0.408, 0.125)
	else:
		modulate = Color(0.033, 0.365, 0.256, 1.0)
