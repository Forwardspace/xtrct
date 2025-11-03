extends Label

signal timer_expire

@export var time_left = 0

const FLASH_TIME = 0.5
var flashing_timer = FLASH_TIME

func _process(delta):
	if time_left > 0:
		flashing_timer -= delta
		if flashing_timer <= 0:
			flashing_timer = FLASH_TIME
			visible = not visible
		
		time_left -= delta
		if time_left <= 0:
			timer_expire.emit()
		
		text = "EXECUTING IN %.2f" % time_left
	else:
		visible = false
