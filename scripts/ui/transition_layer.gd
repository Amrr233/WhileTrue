extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect

func fade_and_reload_scene() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
	tween.tween_callback(get_tree().reload_current_scene)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.3)
