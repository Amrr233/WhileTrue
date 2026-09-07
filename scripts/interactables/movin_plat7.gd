extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(150, 0) # How far to move (X, Y)
@export var duration: float = 2.0 # How many seconds it takes to move one way

var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	_start_moving()

func _start_moving() -> void:
	# Create a tween that loops infinitely
	var tween = create_tween().set_loops()
	
	# Move to the target position smoothly
	tween.tween_property(self, "global_position", start_position + move_offset, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Move back to the start position smoothly
	tween.tween_property(self, "global_position", start_position, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
