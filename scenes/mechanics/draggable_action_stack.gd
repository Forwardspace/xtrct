extends Node2D

@export var default_sprite: CompressedTexture2D = null
@export var default_type: String = ""
@export var stack_size: int = 3

@export var action_scene: PackedScene = null

var actions = []

func action_returned(action):
	if (actions.size() > 0):
		actions[0].visible = false
	else:
		$Placeholder.visible = false

	actions.insert(0, action)

func action_detached(action):
	# Assume it's the topmost one
	actions.erase(action)
	
	if (actions.size() > 0):
		actions[0].visible = true
	else:
		$Placeholder.visible = true

func _ready():
	$Placeholder.texture = default_sprite
	
	# Make a stack of actions, only the topmost one being visible
	for i in range(stack_size):
		var action = action_scene.instantiate()
		action.position.x = -16
		action.position.y = 18
		action.texture = default_sprite
		action.type = default_type
		action.visible = false
		
		action.returned_to_original.connect(action_returned)
		action.detached_from_stack.connect(action_detached)
		
		actions.append(action)
		add_child(action)
	
	actions.reverse()
	actions[0].visible = true

func _process(delta):
	$Counter.text = "x" + str(actions.size())
