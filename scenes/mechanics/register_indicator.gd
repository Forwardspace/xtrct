extends Node2D

func _ready():
	get_tree().create_tween().tween_property($ind_top, "position", Vector2(0, -13), 0.2)
	get_tree().create_tween().tween_property($ind_bottom, "position", Vector2(0, 13), 0.2)
