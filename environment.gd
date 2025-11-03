extends Node2D

const MIN_ZOOM = 0.5
const MAX_ZOOM = 5
const ZOOM_INTERVAL = 1.1

@export var fog_of_war_effect: ColorRect = null;

const CELL_SIZE = 32

func get_room_by_cell_point(point):
	var pointGlobal = to_global(point * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2))
	for room in $rooms.get_children():
		var room_sprite = room.get_child(0)
		if room_sprite.get_rect().has_point(room_sprite.to_local(pointGlobal)):
			return room
			
	return null

func get_doorway_by_cell_point(point):
	var pointGlobal = to_global(point * CELL_SIZE) + Vector2(16, 16)
	for doorway in $doorways.get_children():
		if doorway.get_rect().has_point(doorway.to_local(pointGlobal)):
			return doorway
	return null

func _ready():
	pass # Replace with function body.

var isDragging = false

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		# Map drag
		isDragging = event.pressed
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# Zoom in
		if scale.x > MIN_ZOOM:
			scale.x /= ZOOM_INTERVAL
			scale.y /= ZOOM_INTERVAL
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		# Zoom out
		if scale.x < MAX_ZOOM:
			scale.x *= ZOOM_INTERVAL
			scale.y *= ZOOM_INTERVAL
	if event is InputEventMouseMotion and isDragging:
		position += event.relative

func _process(delta):
	var shaderMat = fog_of_war_effect.material
	shaderMat.set_shader_parameter("map_position_global", position)
	shaderMat.set_shader_parameter("camera_zoom", global_scale)
	shaderMat.set_shader_parameter("viewport_size", get_viewport_rect().size)
