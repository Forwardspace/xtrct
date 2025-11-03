extends Node2D

@export var remote_state: Node2D = null
@export var registers: Node2D = null
@export var countdown_timer: Control = null

const EXEC_GRACE_TIME = 10

var is_ready = false

var exec_step_index = 0

signal execute_player_step_index
signal execute_step_basic_move_once
signal execute_step_basic_attack_once

func switch_stage(_stage):
	is_ready = false
	exec_step_index = 0

func start_countdown_timer():
	countdown_timer.time_left = EXEC_GRACE_TIME

func player_step():
	execute_player_step_index.emit(exec_step_index)
	
	if exec_step_index >= registers.contents.size():
		return # Nothing to execute for this step (for the player)
		
	# Todo: replace with actual (compartmentalized) action handling mechanism
	# and not just if else statements
	if registers.contents[exec_step_index] == "basic_move":
		execute_step_basic_move_once.emit()
	elif registers.contents[exec_step_index] == "basic_attack":
		execute_step_basic_attack_once.emit()

func enemy_step():
	for enemy in remote_state.peers:
		if exec_step_index >= enemy.register_contents.size():
			continue # Nothing to execute for this step (for this enemy)
	
		# Todo: same as above
		if enemy.register_contents[exec_step_index] == "basic_move":
			enemy.move_one()
		elif enemy.register_contents[exec_step_index] == "basic_attack":
			pass # Todo

func execute_step():
	player_step()
	enemy_step()
	
	exec_step_index += 1
	
func _input(event):
	if event.is_action_pressed("ready"):
		is_ready = not is_ready
		remote_state.on_ready_change.rpc(is_ready)

func _ready():
	remote_state.execute_step.connect(execute_step)
	remote_state.switched_stage.connect(switch_stage)
	remote_state.warned_exec_start.connect(start_countdown_timer)
	
	countdown_timer.timer_expire.connect(remote_state.exec_timer_expire)
