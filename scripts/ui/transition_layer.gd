extends CanvasLayer
## Reusable scene transition manager. This node is an Autoload.

@onready var fade_rect: ColorRect = $FadeRect
var _busy := false

func _ready() -> void:
	fade_rect.modulate.a = 0.0

func fade_and_reload_scene() -> void:
	fade_to_scene(get_tree().current_scene.scene_file_path, 0.3)

func fade_to_scene(scene_path: String, duration: float = 0.3) -> void:
	if _busy:
		return
	_busy = true

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.tween_callback(func() -> void:
		var error := get_tree().change_scene_to_file(scene_path)
		if error != OK:
			push_error("Failed to change scene: %s (error %s)" % [scene_path, error])
	)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		_busy = false
	)
