extends AnimatableBody2D

@export var right_distance: float = 220.0  
@export var left_distance: float = 100.0   
@export var speed: float = 80.0            

var _tween: Tween

func _ready() -> void:
	_start_moving()

func _start_moving() -> void:
	var center_pos = position
	var right_pos = center_pos + Vector2(right_distance + 30, 0.0)
	var left_pos = center_pos - Vector2(left_distance, 0.0)
	
	var time_to_right = right_distance / speed
	var total_full_trip = (right_distance + left_distance) / speed
	var time_to_center = left_distance / speed

	_tween = create_tween().set_loops()
	_tween.tween_property(self, "position", right_pos, time_to_right).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position", left_pos, total_full_trip).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position", center_pos, time_to_center).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
