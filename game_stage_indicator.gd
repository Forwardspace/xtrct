extends Label

@export var remote_state: Node2D = null

@export var plan_stage_col = Color.RED
@export var execute_stage_col = Color.GREEN

const blinkTime = 0.5

var blinkStage = false
var blinkTimer = blinkTime

func _ready():
	pass

func _process(delta):
	if remote_state.game_stage == "record":
		modulate = plan_stage_col
		text = "> record"
	elif remote_state.game_stage == "execute":
		modulate = execute_stage_col
		text = "> execute"
	
	if blinkStage:
		text += "_"
	
	blinkTimer -= delta
	if blinkTimer < 0:
		blinkTimer = blinkTime
		blinkStage = not blinkStage
