extends Sprite2D

signal returned_to_original
signal detached_from_stack

@export var type: String = ""

var original_position = null

var mouse_inside = false
var dragging_over_droppables = []
var attached_to_droppable = null
var dragging = false

func mouse_entered():
	mouse_inside = true

func mouse_exited():
	mouse_inside = false

func _input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			if not dragging and mouse_inside:
				dragging = true
				get_viewport().set_input_as_handled()
				
				if global_position == original_position:
					detached_from_stack.emit(self)
		elif event.is_released():
			if dragging:
				# First detach from existing droppable and remove that
				# droppable from the list of potential attachment points
				# (i.e. prevent reattaching (todo: maybe re-add?))
				if attached_to_droppable != null:
					attached_to_droppable.detach_action()
					attached_to_droppable = null
					
				var did_attach_to_droppable = false
				
				if dragging_over_droppables.size() != 0:
					# Try to attach to first droppable that we can
					# starting from the last one dragged over
					dragging_over_droppables.reverse()
					for droppable in dragging_over_droppables:
						if droppable.assign_action(self):
							attached_to_droppable = droppable
							did_attach_to_droppable = true
							break
				if not did_attach_to_droppable and global_position != original_position:
					# Return to starting position
					returned_to_original.emit(self)
					global_position = original_position
						
			dragging_over_droppables = []
			dragging = false

func area_entered(area):
	# Checks if dragged over a register
	if area.get_parent().get_meta("droppable_type") == "register":
		if not dragging_over_droppables.bsearch(area.get_parent()):
			dragging_over_droppables.append(area.get_parent())

func area_exited(area):
	if dragging_over_droppables.bsearch(area.get_parent()):
		dragging_over_droppables.erase(area.get_parent())

func _ready():
	$Collider.mouse_entered.connect(mouse_entered)
	$Collider.mouse_exited.connect(mouse_exited)
	$Collider.area_entered.connect(area_entered)
	$Collider.area_exited.connect(area_exited)
	
	original_position = global_position

func _process(delta):
	if dragging:
		# Follow mouse
		global_position = get_viewport().get_mouse_position()
