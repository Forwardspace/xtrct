extends Label

@export var local_state: Node2D = null
@export var remote_state: Node2D = null

func _ready():
	pass # Replace with function body.

func _process(delta):
	visible = local_state.is_ready and remote_state.game_stage == "record"
