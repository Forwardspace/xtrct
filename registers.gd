extends Node2D

var contents = []

@export var num_registers: int = 10
@export var register_scene: PackedScene = null
@export var register_indicator_scene: PackedScene = null
@export var local_state: Node2D = null
@export var remote_state: Node2D = null

const CELL_SIZE = 35

func register_action_changed(content, index):
	# Update and send the current register contents to server
	contents[index] = content
	remote_state.on_register_contents_change.rpc(contents)
	
func get_reg_position(idx):
	return idx * CELL_SIZE - num_registers * CELL_SIZE / 2

func show_hide_indicator(idx):
	if idx > 0:
		# Hide previous indicator
		get_child(-1).queue_free()
	if idx >= num_registers:
		return
	
	# Show indicator at specified index
	var indicator = register_indicator_scene.instantiate()
	indicator.position = Vector2(get_reg_position(idx), 0)
	add_child(indicator)

func set_reg_count(count):
	num_registers = count

	var children = get_children()
	for child in children:
		child.free()
		
	for i in range(num_registers):
		var reg = register_scene.instantiate()
		reg.reg_index = i
		reg.position.x = get_reg_position(i)
		reg.local_state = local_state
		reg.attached_action_changed.connect(register_action_changed)
		
		if i >= 3 and i <= 6:
			reg.is_enabled = true
		
		add_child(reg)
		
		contents.append(null)

func _ready():
	set_reg_count(num_registers)
	local_state.execute_player_step_index.connect(show_hide_indicator)
