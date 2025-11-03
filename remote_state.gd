extends Node2D

var game_stage = "record"
var peers = []

signal switched_stage
signal execute_step
signal warned_exec_start

const EXECUTE_STEP_LENGTH = 1
const NUM_EXECUTE_STEPS = 10
const CELL_SIZE = 32

@export var player: Sprite2D = null
@export var enemy_player_scene: PackedScene = null
@export var environment: Node2D = null

var execute_countdown_started = false

func get_peer_by_id(id):
	for p in peers:
		if p.peer_id == id:
			return p
	return null

# Client -> Server

@rpc("any_peer", "call_remote", "reliable")
func on_ready_change(is_ready):
	var peer = multiplayer.get_remote_sender_id()
	
	get_peer_by_id(peer).is_ready = is_ready

@rpc("any_peer", "call_remote", "reliable")
func on_register_contents_change(contents):
	var peer = multiplayer.get_remote_sender_id()
	
	get_peer_by_id(peer).register_contents = contents

@rpc("any_peer", "call_remote", "reliable")
func on_move_target_change(target, path):
	var peer = multiplayer.get_remote_sender_id()
	
	get_peer_by_id(peer).move_target = target
	get_peer_by_id(peer).move_path = path

# Server -> Client
	
@rpc("authority", "call_local", "reliable")
func on_switch_stage(new_stage):
	game_stage = new_stage
	execute_countdown_started = false
	for peer in peers:
		peer.is_ready = false
	
	switched_stage.emit(game_stage)
	
@rpc("authority", "call_local", "reliable")
func on_execute_step():
	execute_step.emit()
	
@rpc("authority", "call_local", "reliable")
func on_warn_execute_start():
	execute_countdown_started = true
	warned_exec_start.emit()
	
@rpc("authority", "call_local", "reliable")
func on_set_player_position(player_id, pos):
	if player_id == multiplayer.get_unique_id():
		# This is us
		player.cell_position = pos
	else:
		# This is an enemy player
		for peer in peers:
			if peer.peer_id == player_id:
				peer.cell_position = pos

# Server

func exec_timer_expire():
	if multiplayer.is_server():
		on_switch_stage.rpc("execute") 
	
func num_not_ready():
	if peers.size() < 2:
		return -1 
		
	var num = 0
	for p in peers:
		if not p.is_ready:
			num += 1
			
	return num	
	
var step_timer = EXECUTE_STEP_LENGTH
var step_num = 0

func serv_wait_for_exec_step(delta):
	step_timer -= delta
	if step_timer <= 0:
		step_timer = EXECUTE_STEP_LENGTH
		
		if step_num > NUM_EXECUTE_STEPS:
			on_switch_stage.rpc("record")
			step_num = 0
			return
		
		on_execute_step.rpc()
		step_num += 1

func _process(delta):
	if multiplayer.is_server():
		if game_stage == "record":
			if not execute_countdown_started and num_not_ready() == 0:
				on_switch_stage.rpc("execute")
			elif not execute_countdown_started and num_not_ready() == 1:
				on_warn_execute_start.rpc()
		elif game_stage == "execute":
			serv_wait_for_exec_step(delta)

func on_peer_connected(id):
	if id == 1:
		return # No need to add character for server
	var newPeer = enemy_player_scene.instantiate()
	newPeer.peer_id = id
	newPeer.environment = environment
	newPeer.player = player
	
	environment.add_child(newPeer)
	peers.append(newPeer)
	
	if multiplayer.is_server():
		var rooms = range(peers.size())
		rooms.shuffle()
		
		for i in range(peers.size()):
			var pos = environment.get_child(0).get_child(rooms[i]).position / CELL_SIZE
			pos += Vector2(1, 1)
			
			on_set_player_position.rpc(peers[i].peer_id, pos)
	
func on_peer_disconnected(id):
	var peer = get_peer_by_id(id)
	peers.erase(peer)
	peer.queue_free()

func _ready():
	if OS.has_feature("dedicated_server"):
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(5738, 6)
		multiplayer.multiplayer_peer = peer
	else:
		var peer = ENetMultiplayerPeer.new()
		peer.create_client("localhost", 5738)
		multiplayer.multiplayer_peer = peer
		
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
