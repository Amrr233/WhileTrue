extends AnimatableBody2D

@export var middle_offset: Vector2 = Vector2(0, -150) # The stop in front of the player
@export var top_offset: Vector2 = Vector2(0, -400)    # The final stop above the screen
@export var move_speed: float = 1.0 
@export var wait_time: float = 1.5 

var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	_start_moving()

func _start_moving() -> void:
	var tween = create_tween().set_loops()
	
	# 1. Move from Taskbar up to the Middle
	tween.tween_property(self, "global_position", start_position + middle_offset, move_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Wait at the Middle (blocks the player)
	tween.tween_interval(wait_time)
	
	# 2. Move from Middle up to the Top
	tween.tween_property(self, "global_position", start_position + top_offset, move_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# Wait at the Top (lets the player pass underneath)
	tween.tween_interval(wait_time)
	
	# 3. Go straight back down to the Taskbar to loop again
	tween.tween_property(self, "global_position", start_position, move_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# Wait at the Taskbar before starting over
	tween.tween_interval(wait_time)
